awk '{gsub(/[,"]/, "")} /version/ {print $2}' mix.exs
