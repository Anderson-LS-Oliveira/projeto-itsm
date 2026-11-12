import csv
import json
import logging
import os
import tempfile
from datetime import date, datetime, timezone
from decimal import Decimal

import pyodbc

FORMATO = "csv"

CONTAINER = "bronze"
FONTE = "itsm"
SCHEMA_ORIGEM = "itsm"
TAMANHO_LOTE = 5000

TABELAS = {
    "categoria": "categoria",
    "cliente_organizacao": "cliente_organizacao",
    "fila": "fila",
    "sla": "sla",
    "analista": "analista",
    "solicitante": "solicitante",
    "chamado": "chamado",
    "chamado_sla": "chamado_sla",
    "chamado_status_historico": "chamado_status_historico",
    "csat_avaliacao": "csat_avaliacao",
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("bronze")


def serializar_json(valor):
    if isinstance(valor, (datetime, date)):
        return valor.isoformat()
    if isinstance(valor, Decimal):
        return float(valor)
    if isinstance(valor, (bytes, bytearray)):
        return valor.hex()
    raise TypeError(f"Tipo não serializável: {type(valor)}")


def valor_csv(valor):
    if valor is None:
        return ""
    if isinstance(valor, bool):
        return 1 if valor else 0
    if isinstance(valor, (datetime, date)):
        return valor.isoformat(sep=" ") if isinstance(valor, datetime) else valor.isoformat()
    if isinstance(valor, Decimal):
        return str(valor)
    if isinstance(valor, (bytes, bytearray)):
        return valor.hex()
    return valor


def caminho_blob(entidade: str, agora: datetime) -> str:
    ts = agora.strftime("%Y%m%dT%H%M%SZ")
    return (
        f"{FONTE}/{entidade}/"
        f"ano={agora:%Y}/mes={agora:%m}/dia={agora:%d}/"
        f"{entidade}_{ts}.{FORMATO}"
    )


def extrair_para_arquivo(cursor, tabela: str, caminho_tmp: str) -> int:
    cursor.execute(f"SELECT * FROM [{SCHEMA_ORIGEM}].[{tabela}]")
    colunas = [c[0] for c in cursor.description]
    total = 0

    if FORMATO == "csv":
        with open(caminho_tmp, "w", encoding="utf-8", newline="") as f:
            escritor = csv.writer(f, delimiter=",", quoting=csv.QUOTE_MINIMAL)
            escritor.writerow(colunas)
            while True:
                linhas = cursor.fetchmany(TAMANHO_LOTE)
                if not linhas:
                    break
                for linha in linhas:
                    escritor.writerow([valor_csv(v) for v in linha])
                    total += 1
    else:
        with open(caminho_tmp, "w", encoding="utf-8") as f:
            f.write("[")
            primeiro = True
            while True:
                linhas = cursor.fetchmany(TAMANHO_LOTE)
                if not linhas:
                    break
                for linha in linhas:
                    if not primeiro:
                        f.write(",\n")
                    json.dump(dict(zip(colunas, linha)), f, default=serializar_json, ensure_ascii=False)
                    primeiro = False
                    total += 1
            f.write("]")
    return total


def main():
    agora = datetime.now(timezone.utc)

    conn = pyodbc.connect(os.environ["SQL_CONN_STR"])

    from azure.storage.blob import BlobServiceClient

    blob_service = BlobServiceClient.from_connection_string(os.environ["AZURE_STORAGE_CONNECTION_STRING"])
    container = blob_service.get_container_client(CONTAINER)
    if not container.exists():
        container.create_container()

    try:
        cursor = conn.cursor()
        for tabela, entidade in TABELAS.items():
            destino = caminho_blob(entidade, agora)
            with tempfile.NamedTemporaryFile(suffix=f".{FORMATO}", delete=False) as tmp:
                caminho_tmp = tmp.name
            try:
                qtd = extrair_para_arquivo(cursor, tabela, caminho_tmp)
                with open(caminho_tmp, "rb") as dados:
                    container.upload_blob(destino, dados, overwrite=True)
                log.info("%s: %d registros -> %s/%s", tabela, qtd, CONTAINER, destino)
            except Exception:
                log.exception("Falha ao extrair a tabela %s", tabela)
                raise
            finally:
                os.remove(caminho_tmp)
    finally:
        conn.close()


if __name__ == "__main__":
    main()