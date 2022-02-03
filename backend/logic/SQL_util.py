import simplejson as json

import psycopg


def kwargs_to_where_clause(kwargs: dict) -> str:
    return "WHERE " + " AND ".join([key + " = " + str(value) for key, value in kwargs.items()]) if len(kwargs) > 0 else ""


def query_to_dict_list(cursor: psycopg.cursor, query: str, **kwargs) -> list[dict]:
    query = f"{query} {kwargs_to_where_clause(kwargs)}"
    res = cursor.execute(query).fetchall()
    columns = [desc.name for desc in cursor.description]
    return [{column: r[index] for index, column in enumerate(columns)} for r in res]


def query_to_json(cursor: psycopg.cursor, query: str, **kwargs) -> str:
    return json.dumps(query_to_dict_list(cursor, query, **kwargs))


def table_to_dict_list(cursor: psycopg.cursor, table: str, **kwargs) -> list[dict]:
    return query_to_dict_list(cursor, f"SELECT * FROM {table}", **kwargs)


def table_to_json(cursor: psycopg.cursor, table: str, **kwargs) -> str:
    return_single = kwargs.pop('single', False)
    res = table_to_dict_list(cursor, table, **kwargs)
    if return_single:
        return json.dumps(res[0])
    else:
        return json.dumps(res)


def sql_function_to_dict_list(cursor: psycopg.cursor, function_name: str, params: tuple, **kwargs) -> list[dict]:
    param_string = ', '.join(map(str, params))
    return query_to_dict_list(cursor, f"SELECT * from {function_name}({param_string})", **kwargs)


def sql_function_to_json(cursor: psycopg.cursor, function_name: str, params: tuple, **kwargs) -> str:
    return json.dumps(sql_function_to_dict_list(cursor, function_name, params, **kwargs))


def exec_sql_statement(cursor: psycopg.cursor, script: str, script_name: str) -> None:
    cursor.execute(script)


def exec_sql_statement_from_file(cursor: psycopg.cursor, path: str) -> None:
    with open(path) as script:
        exec_sql_statement(cursor, script.read(), path)


def key_dict(cursor: psycopg.cursor, table: str, keys: tuple[str, ...], target: str) -> dict:
    keys = tuple(map(lambda key: key.lower(), keys))
    target = target.lower()
    return {tuple(row[key] for key in keys): row[target] for row in table_to_dict_list(cursor, table)}


def get_column_names(cursor: psycopg.cursor, table: str) -> list[str]:
    cursor.execute(f"SELECT * FROM {table}")
    col_names = [desc[0] for desc in cursor.description]
    return col_names


def load_into_db(cursor: psycopg.cursor, records: list, table: str) -> None:
    col_names = get_column_names(cursor, table)
    record_len = len(records[0])
    # Cut columns if necessary
    col_names = col_names[:record_len]
    with cursor.copy(f'COPY  {table}({",".join(col_names)}) FROM STDIN') as copy:
        for record in records:
            copy.write_row(record)
