return {
    [1] =     {
        field = "varchar",
        type = "VARCHAR",
        limit = 100,
        default = "default varchar",
        not_null = true,
        primary = true,
    },
    [2] =     {
        field = "text",
        type = "TEXT",
        default = "default long text",
        not_null = true,
    },
    [3] =     {
        field = "enum",
        type = "ENUM",
        allowed = {
            [1] = "value1",
            [2] = "value2",
            [3] = "value3",
        },
        default = "value2",
        not_null = true,
    },
    [4] =     {
        field = "tinyint",
        type = "TINYINT",
        default = 1,
        not_null = true,
    },
    [5] =     {
        field = "smallint",
        type = "SMALLINT",
        default = 123,
        not_null = true,
    },
    [6] =     {
        field = "int",
        type = "INT",
        auto_increment = true,
        default = 0,
        not_null = true,
    },
    [7] =     {
        field = "bigint",
        type = "BIGINT",
        default = 1000000,
        not_null = true,
    },
    [8] =     {
        field = "decimal",
        type = "DECIMAL",
        default = 123.45,
        not_null = true,
    },
    [9] =     {
        field = "float",
        type = "FLOAT",
        default = 1.23,
        not_null = true,
    },
    [10] =     {
        field = "date",
        type = "DATE",
        default = "2025-03-09",
        not_null = true,
    },
    [11] =     {
        field = "datetime",
        type = "DATETIME",
        default = "2025-03-09 22:00:00",
        not_null = true,
    },
    [12] =     {
        field = "timestamp",
        type = "TIMESTAMP",
        default = "CURRENT_TIMESTAMP",
        not_null = true,
    },
    [13] =     {
        field = "json",
        type = "JSON",
        default = {
        },
        not_null = true,
    },
}