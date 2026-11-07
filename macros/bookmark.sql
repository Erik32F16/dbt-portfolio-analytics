{% macro bookmark(field, table, default="'1900-01-01'") %}
    {% if execute %}
        {% set relation = adapter.get_relation(
            database=table.database,
            schema=table.schema,
            identifier=table.identifier
        ) %}

        {% if relation is not none %}
            (
                SELECT COALESCE(MAX({{ field }}), {{ default }})
                FROM {{ table }}
            )
        {% else %}
            {{ default }}
        {% endif %}
    {% else %}
        {{ default }}
    {% endif %}
{% endmacro %}
