{% set configs = [
    {
        "table": "AIRBNB.GOLD.OBT",
        "columns": "
            GOLD_obt.BOOKING_ID,
            GOLD_obt.LISTING_ID,
            GOLD_obt.TOTAL_AMOUNT,
            GOLD_obt.SERVICE_FEE,
            GOLD_obt.CLEANING_FEE,
            GOLD_obt.BOOKING_STATUS,
            GOLD_obt.CREATED_AT,
            GOLD_obt.HOST_NAME
        ",
        "alias": "GOLD_obt"
    },
    {
        "table": "AIRBNB.GOLD.DIM_LISTINGS",
        "alias": "DIM_LISTINGS",
        "join_condition": "GOLD_obt.LISTING_ID = DIM_LISTINGS.LISTING_ID"
    },
    {
        "table": "AIRBNB.GOLD.DIM_HOSTS",
        "alias": "DIM_HOSTS",
        "join_condition": "GOLD_obt.HOST_NAME = DIM_HOSTS.HOST_NAME"
    }
] %}

SELECT
    {{ configs[0]['columns'] }}

FROM
    {% for config in configs %}
        {% if loop.first %}
            {{ config['table'] }} AS {{ config['alias'] }}
        {% else %}
            LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
            ON {{ config['join_condition'] }}
        {% endif %}
    {% endfor %}