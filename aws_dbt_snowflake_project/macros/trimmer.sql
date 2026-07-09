{% macro trimmer(column,node) %}
   {column | trim |upper }
{% endmacro %}