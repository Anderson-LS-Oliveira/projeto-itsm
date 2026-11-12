CREATE TABLE dbo.categoria (
    id_categoria        int            NOT NULL,
    cd_categoria        nvarchar(50)   NOT NULL,
    nm_categoria        nvarchar(150)  NOT NULL,
    ds_descricao        nvarchar(300)  NULL,
    fl_ativo            bit            NOT NULL CONSTRAINT DF_categoria_ativo DEFAULT 1,
    dt_inclusao         datetime2(0)   NOT NULL CONSTRAINT DF_categoria_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao      datetime2(0)   NULL,
    nm_sistema_origem   nvarchar(100)  NULL,
    cd_registro_origem  nvarchar(100)  NULL,
    CONSTRAINT PK_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_categoria_cd UNIQUE (cd_categoria)
);
GO

CREATE TABLE dbo.cliente_organizacao (
    id_cliente_organizacao  int            NOT NULL,
    cd_cliente_organizacao  nvarchar(50)   NOT NULL,
    nm_cliente_organizacao  nvarchar(200)  NOT NULL,
    nr_cnpj                 nvarchar(20)   NULL,
    fl_ativo                bit            NOT NULL CONSTRAINT DF_cliente_org_ativo DEFAULT 1,
    dt_inclusao             datetime2(0)   NOT NULL CONSTRAINT DF_cliente_org_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao          datetime2(0)   NULL,
    nm_sistema_origem       nvarchar(100)  NULL,
    cd_registro_origem      nvarchar(100)  NULL,
    CONSTRAINT PK_cliente_organizacao PRIMARY KEY (id_cliente_organizacao),
    CONSTRAINT UQ_cliente_organizacao_cd UNIQUE (cd_cliente_organizacao)
);
GO

CREATE TABLE dbo.fila (
    id_fila             int            NOT NULL,
    cd_fila             nvarchar(50)   NOT NULL,
    nm_fila             nvarchar(150)  NOT NULL,
    ds_descricao        nvarchar(300)  NULL,
    fl_ativo            bit            NOT NULL CONSTRAINT DF_fila_ativo DEFAULT 1,
    dt_inclusao         datetime2(0)   NOT NULL CONSTRAINT DF_fila_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao      datetime2(0)   NULL,
    nm_sistema_origem   nvarchar(100)  NULL,
    cd_registro_origem  nvarchar(100)  NULL,
    CONSTRAINT PK_fila PRIMARY KEY (id_fila),
    CONSTRAINT UQ_fila_cd UNIQUE (cd_fila)
);
GO

CREATE TABLE dbo.sla (
    id_sla              int            NOT NULL,
    cd_sla              nvarchar(50)   NOT NULL,
    nm_sla              nvarchar(150)  NOT NULL,
    qt_meta_minutos     int            NOT NULL,
    ds_descricao        nvarchar(300)  NULL,
    fl_ativo            bit            NOT NULL CONSTRAINT DF_sla_ativo DEFAULT 1,
    dt_inclusao         datetime2(0)   NOT NULL CONSTRAINT DF_sla_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao      datetime2(0)   NULL,
    nm_sistema_origem   nvarchar(100)  NULL,
    cd_registro_origem  nvarchar(100)  NULL,
    CONSTRAINT PK_sla PRIMARY KEY (id_sla),
    CONSTRAINT UQ_sla_cd UNIQUE (cd_sla)
);
GO

CREATE TABLE dbo.analista (
    id_analista         int            NOT NULL,
    cd_analista         nvarchar(50)   NOT NULL,
    nm_analista         nvarchar(200)  NOT NULL,
    ds_email            nvarchar(200)  NULL,
    ds_nivel            nvarchar(10)   NOT NULL,
    id_fila_atual       int            NULL,
    fl_ativo            bit            NOT NULL CONSTRAINT DF_analista_ativo DEFAULT 1,
    dt_inclusao         datetime2(0)   NOT NULL CONSTRAINT DF_analista_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao      datetime2(0)   NULL,
    nm_sistema_origem   nvarchar(100)  NULL,
    cd_registro_origem  nvarchar(100)  NULL,
    CONSTRAINT PK_analista PRIMARY KEY (id_analista),
    CONSTRAINT UQ_analista_cd UNIQUE (cd_analista),
    CONSTRAINT FK_analista_fila FOREIGN KEY (id_fila_atual) REFERENCES dbo.fila(id_fila),
    CONSTRAINT CK_analista_nivel CHECK (ds_nivel IN ('N1','N2','N3'))
);
CREATE NONCLUSTERED INDEX IX_analista_fila ON dbo.analista (id_fila_atual);
GO

CREATE TABLE dbo.solicitante (
    id_solicitante          int            NOT NULL,
    cd_solicitante          nvarchar(50)   NOT NULL,
    id_cliente_organizacao  int            NOT NULL,
    nm_solicitante          nvarchar(200)  NOT NULL,
    ds_email                nvarchar(200)  NULL,
    ds_telefone             nvarchar(50)   NULL,
    fl_ativo                bit            NOT NULL CONSTRAINT DF_solicitante_ativo DEFAULT 1,
    dt_inclusao             datetime2(0)   NOT NULL CONSTRAINT DF_solicitante_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao          datetime2(0)   NULL,
    nm_sistema_origem       nvarchar(100)  NULL,
    cd_registro_origem      nvarchar(100)  NULL,
    CONSTRAINT PK_solicitante PRIMARY KEY (id_solicitante),
    CONSTRAINT UQ_solicitante_cd UNIQUE (cd_solicitante),
    CONSTRAINT FK_solicitante_cliente_org FOREIGN KEY (id_cliente_organizacao)
        REFERENCES dbo.cliente_organizacao(id_cliente_organizacao)
);
CREATE NONCLUSTERED INDEX IX_solicitante_cliente_org ON dbo.solicitante (id_cliente_organizacao);
GO

CREATE TABLE dbo.chamado (
    id_chamado              bigint         NOT NULL,
    nr_chamado              nvarchar(50)   NOT NULL,
    ds_tipo_chamado         nvarchar(50)   NOT NULL,
    ds_status_chamado       nvarchar(30)   NOT NULL,
    ds_prioridade           nvarchar(20)   NOT NULL,
    dt_criacao              datetime2(0)   NOT NULL,
    dt_resolucao            datetime2(0)   NULL,
    dt_ultima_atualizacao   datetime2(0)   NOT NULL,
    id_analista_atual       int            NULL,
    id_reporter             int            NOT NULL,
    id_categoria            int            NULL,
    id_cliente_organizacao  int            NOT NULL,
    id_fila_atual           int            NULL,
    ds_titulo               nvarchar(250)  NULL,
    ds_descricao            nvarchar(MAX)  NULL,
    dt_inclusao             datetime2(0)   NOT NULL CONSTRAINT DF_chamado_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao          datetime2(0)   NULL,
    nm_sistema_origem       nvarchar(100)  NULL,
    cd_registro_origem      nvarchar(100)  NULL,
    CONSTRAINT PK_chamado PRIMARY KEY (id_chamado),
    CONSTRAINT UQ_chamado_nr UNIQUE (nr_chamado),
    CONSTRAINT FK_chamado_analista   FOREIGN KEY (id_analista_atual)      REFERENCES dbo.analista(id_analista),
    CONSTRAINT FK_chamado_categoria  FOREIGN KEY (id_categoria)           REFERENCES dbo.categoria(id_categoria),
    CONSTRAINT FK_chamado_cliente_org FOREIGN KEY (id_cliente_organizacao) REFERENCES dbo.cliente_organizacao(id_cliente_organizacao),
    CONSTRAINT FK_chamado_fila       FOREIGN KEY (id_fila_atual)          REFERENCES dbo.fila(id_fila),
    CONSTRAINT FK_chamado_reporter   FOREIGN KEY (id_reporter)            REFERENCES dbo.solicitante(id_solicitante),
    CONSTRAINT CK_chamado_tipo       CHECK (ds_tipo_chamado IN ('TASK','CHANGE','PROBLEM','REQUEST','INCIDENT')),
    CONSTRAINT CK_chamado_status     CHECK (ds_status_chamado IN ('CANCELLED','CLOSED','RESOLVED','PENDING','IN_PROGRESS','OPEN')),
    CONSTRAINT CK_chamado_prioridade CHECK (ds_prioridade IN ('CRITICAL','HIGH','MEDIUM','LOW'))
);
CREATE NONCLUSTERED INDEX IX_chamado_analista   ON dbo.chamado (id_analista_atual);
CREATE NONCLUSTERED INDEX IX_chamado_categoria  ON dbo.chamado (id_categoria);
CREATE NONCLUSTERED INDEX IX_chamado_cliente_org ON dbo.chamado (id_cliente_organizacao);
CREATE NONCLUSTERED INDEX IX_chamado_criacao    ON dbo.chamado (dt_criacao);
CREATE NONCLUSTERED INDEX IX_chamado_fila       ON dbo.chamado (id_fila_atual);
CREATE NONCLUSTERED INDEX IX_chamado_prioridade ON dbo.chamado (ds_prioridade);
CREATE NONCLUSTERED INDEX IX_chamado_reporter   ON dbo.chamado (id_reporter);
CREATE NONCLUSTERED INDEX IX_chamado_resolucao  ON dbo.chamado (dt_resolucao);
CREATE NONCLUSTERED INDEX IX_chamado_status     ON dbo.chamado (ds_status_chamado);
GO

CREATE TABLE dbo.chamado_sla (
    id_chamado_sla              bigint        NOT NULL,
    id_chamado                  bigint        NOT NULL,
    id_sla                      int           NOT NULL,
    fl_breach                   bit           NOT NULL,
    qt_tempo_restante_minutos   int           NULL,
    qt_tempo_decorrido_minutos  int           NULL,
    qt_meta_minutos             int           NOT NULL,
    dt_referencia               datetime2(0)  NOT NULL,
    dt_inclusao                 datetime2(0)  NOT NULL CONSTRAINT DF_chamado_sla_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao              datetime2(0)  NULL,
    nm_sistema_origem           nvarchar(100) NULL,
    cd_registro_origem          nvarchar(100) NULL,
    CONSTRAINT PK_chamado_sla PRIMARY KEY (id_chamado_sla),
    CONSTRAINT FK_chamado_sla_chamado FOREIGN KEY (id_chamado) REFERENCES dbo.chamado(id_chamado),
    CONSTRAINT FK_chamado_sla_sla     FOREIGN KEY (id_sla)     REFERENCES dbo.sla(id_sla)
);
CREATE NONCLUSTERED INDEX IX_chamado_sla_breach  ON dbo.chamado_sla (fl_breach);
CREATE NONCLUSTERED INDEX IX_chamado_sla_chamado ON dbo.chamado_sla (id_chamado);
CREATE NONCLUSTERED INDEX IX_chamado_sla_sla     ON dbo.chamado_sla (id_sla);
GO

CREATE TABLE dbo.chamado_status_historico (
    id_chamado_status_historico bigint        NOT NULL,
    id_chamado                  bigint        NOT NULL,
    ds_status_chamado           nvarchar(30)  NOT NULL,
    dt_inicio_status            datetime2(0)  NOT NULL,
    dt_fim_status               datetime2(0)  NULL,
    qt_tempo_status_minutos     int           NULL,
    id_analista_responsavel     int           NULL,
    id_fila                     int           NULL,
    dt_inclusao                 datetime2(0)  NOT NULL CONSTRAINT DF_chamado_status_hist_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao              datetime2(0)  NULL,
    nm_sistema_origem           nvarchar(100) NULL,
    cd_registro_origem          nvarchar(100) NULL,
    CONSTRAINT PK_chamado_status_historico PRIMARY KEY (id_chamado_status_historico),
    CONSTRAINT FK_chamado_status_hist_analista FOREIGN KEY (id_analista_responsavel) REFERENCES dbo.analista(id_analista),
    CONSTRAINT FK_chamado_status_hist_chamado  FOREIGN KEY (id_chamado)              REFERENCES dbo.chamado(id_chamado),
    CONSTRAINT FK_chamado_status_hist_fila     FOREIGN KEY (id_fila)                 REFERENCES dbo.fila(id_fila),
    CONSTRAINT CK_chamado_status_hist_status CHECK (ds_status_chamado IN ('CANCELLED','CLOSED','RESOLVED','PENDING','IN_PROGRESS','OPEN'))
);
CREATE NONCLUSTERED INDEX IX_chamado_status_hist_chamado ON dbo.chamado_status_historico (id_chamado);
CREATE NONCLUSTERED INDEX IX_chamado_status_hist_inicio  ON dbo.chamado_status_historico (dt_inicio_status);
CREATE NONCLUSTERED INDEX IX_chamado_status_hist_status  ON dbo.chamado_status_historico (ds_status_chamado);
GO

CREATE TABLE dbo.csat_avaliacao (
    id_csat_avaliacao   bigint         NOT NULL,
    id_chamado          bigint         NOT NULL,
    id_analista         int            NULL,
    nr_score            int            NOT NULL,
    ds_comentario       nvarchar(1000) NULL,
    dt_avaliacao        datetime2(0)   NOT NULL,
    dt_inclusao         datetime2(0)   NOT NULL CONSTRAINT DF_csat_inclusao DEFAULT sysutcdatetime(),
    dt_atualizacao      datetime2(0)   NULL,
    nm_sistema_origem   nvarchar(100)  NULL,
    cd_registro_origem  nvarchar(100)  NULL,
    CONSTRAINT PK_csat_avaliacao PRIMARY KEY (id_csat_avaliacao),
    CONSTRAINT FK_csat_analista FOREIGN KEY (id_analista) REFERENCES dbo.analista(id_analista),
    CONSTRAINT FK_csat_chamado  FOREIGN KEY (id_chamado)  REFERENCES dbo.chamado(id_chamado),
    CONSTRAINT CK_csat_score CHECK (nr_score BETWEEN 1 AND 5)
);
CREATE NONCLUSTERED INDEX IX_csat_analista ON dbo.csat_avaliacao (id_analista);
CREATE NONCLUSTERED INDEX IX_csat_chamado  ON dbo.csat_avaliacao (id_chamado);
CREATE NONCLUSTERED INDEX IX_csat_data     ON dbo.csat_avaliacao (dt_avaliacao);
GO