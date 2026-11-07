{% macro deduplicate(partition_by, order_by) %}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY {{ partition_by }}
        ORDER BY {{ order_by }} DESC
    ) = 1
{% endmacro %}