changed_models=$(dbt ls --select state:modified+ --state . --quiet)

echo "\nCHANGED MODELS:"
echo $changed_models
echo "\n"
echo "$changed_models" | while IFS= read -r model; do
    echo "SHOWING $model"
    dbt show --select "$model" --limit 10
done

dbt build --select state:modified+ --state . 