# Módulo Core

Generar un motor montable
```sh
docker compose up -d
docker compose exec -it dev /bin/bash
rails plugin new core --mountable --skip-test-unit
```

Crear una carpeta engines y mover la carpeta core adentro
```sh
mkdir engines
mv core engines/
```
Todos los engines se ubicarán en esta carpeta para mantener el código organizado.
