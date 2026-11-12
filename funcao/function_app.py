import csv
import io
import logging
import os

import azure.functions as func
import pyodbc

app = func.FunctionApp()

CONTAINER = "bronze"
FONTE = "itsm"

csv.field_size_limit(10_000_000)

TABELAS = [
    ("categoria", "categoria", "id_categoria"),
    ("cliente_organizacao", "cliente_organizacao", "id_cliente_organizacao"),
    ("fila", "fila", "id_fila"),
    ("sla", "sla", "id_sla"),
    ("analista", "analista", "id_analista"),
    ("solicitante", "solicitante", "id_solicitante"),
    ("chamado", "chamado", "id_chamado"),
    ("chamado_sla", "chamado_sla", "id_chamado_sla"),
    ("chamado_status_historico", "chamado_status_historico", "id_chamado_status_historico"),
    ("csat_avaliacao", "csat_avaliacao", "id_csat_avaliacao"),
]


def conectar_destino():
    senha = os.environ["PASSWORD"].replace("}", "}}")
    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{os.environ['HOST']},1433;"
        f"Database={os.environ['DATABASE']};"
        f"Uid={os.environ['USER']};"
        f"Pwd={{{senha}}};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    return pyodbc.connect(conn_str)


def ultimo_csv(container, entidade):
    prefixo = f"{FONTE}/{entidade}/"
    nomes = [b.name for b in container.list_blobs(name_starts_with=prefixo) if b.name.endswith(".csv")]
    if not nomes:
        raise FileNotFoundError(f"Nenhum CSV em {CONTAINER}/{prefixo}")
    return max(nomes)


def ler_csv(container, nome):
    texto = container.download_blob(nome).readall().decode("utf-8")
    leitor = csv.reader(io.StringIO(texto, newline=""))
    colunas = next(leitor)
    linhas = [[(v if v != "" else None) for v in linha] for linha in leitor]
    return colunas, linhas


def upsert(cursor, tabela, pk, colunas, linhas):
    if not linhas:
        return 0
    destino = f"dbo.{tabela}"
    lista_cols = ", ".join(f"[{c}]" for c in colunas)
    marcadores = ", ".join("?" for _ in colunas)

    cursor.execute(f"SELECT TOP 0 * INTO #stage FROM {destino}")
    cursor.executemany(f"INSERT INTO #stage ({lista_cols}) VALUES ({marcadores})", linhas)

    sets = ", ".join(f"t.[{c}] = s.[{c}]" for c in colunas if c != pk)
    valores = ", ".join(f"s.[{c}]" for c in colunas)
    cursor.execute(
        f"MERGE {destino} AS t "
        f"USING #stage AS s ON t.[{pk}] = s.[{pk}] "
        f"WHEN MATCHED THEN UPDATE SET {sets} "
        f"WHEN NOT MATCHED BY TARGET THEN INSERT ({lista_cols}) VALUES ({valores});"
    )
    cursor.execute("DROP TABLE #stage")
    return len(linhas)


@app.schedule(schedule="0 0 6 * * *", arg_name="timer", run_on_startup=False, use_monitor=False)
def carga_diaria(timer: func.TimerRequest) -> None:
    conn = conectar_destino()
    from azure.storage.blob import BlobServiceClient

    servico = BlobServiceClient.from_connection_string(os.environ["BRONZE_STORAGE_CONNECTION_STRING"])
    container = servico.get_container_client(CONTAINER)

    try:
        cursor = conn.cursor()
        for tabela, entidade, pk in TABELAS:
            nome = ultimo_csv(container, entidade)
            colunas, linhas = ler_csv(container, nome)
            qtd = upsert(cursor, tabela, pk, colunas, linhas)
            logging.info("dbo.%s: %d registros processados (%s)", tabela, qtd, nome)
        conn.commit()
        logging.info("Carga diária concluída.")
    except Exception:
        conn.rollback()
        logging.exception("Falha na carga diária; rollback executado.")
        raise
    finally:
        conn.close()