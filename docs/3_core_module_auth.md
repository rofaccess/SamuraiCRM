# Módulo Core (Autenticación)
Agregar la gema devise
```ruby
# SamuraiCRM/engines/core/samurai_core.gemspec
# ...
s.add_dependency 'devise', '~> 3.4.1'
```

Agregar los correspondientes require dentro del engine
```ruby
# SamuraiCRM/engines/core/lib/samurai/core.rb
require 'sass-rails'
require 'bootstrap-sass'
require 'autoprefixer-rails'
require 'devise'
module Samurai
  module Core
  end
end
```

Ejecutar bundle install desde la aplicación padre.
```bash
docker compose run --rm -p 3000:3000 dev bash
bundle install
rails s -b 0.0.0.0
exit
```

Generar los archivos de devise
```bash
docker compose up
docker compose exec -it dev bash
rails generate devise:install
```

Crear el archivo de configuración de devise
```ruby
# SamuraiCRM/engines/core/config/devise.rb
config.router_name = :samurai
config.parent_controller = 'Samurai::ApplicationController'
```
Esto le dice a Devise que va a ser ejecutado dentro de un engine, en usos normales en una aplicación, los valores por
defecto bastan.

Reorganizar los helpers
```bash
cd engines/core
mv app/helpers/core app/helpers/samurai
```

Agregar el namespace Samurai y un helper para mostrar mensajes flash a application_helper.rb
```ruby
# core/app/helpers/samurai/application_helper.rb
module Samurai
  module ApplicationHelper
    FLASH_CLASSES = {
      notice: "alert alert-info",
      success: "alert alert-success",
      alert: "alert alert-danger",
      error: "alert alert-danger"
    }
    
    def flash_class(level)
      FLASH_CLASSES[level]
    end
  end
end
```

Agregar el código para mostrar mensajes flash en el layout antes del jumbotron
```erb
<!-- SamuraiCRM/engines/core/app/views/layouts/samurai/application.html.erb -->
<!-- ... -->
<% flash.each do |key, value| %>
  <div class="<%= flash_class(key.to_sym) %>"><%= value %></div>
<% end %>
```

Generar el modelo User desde el módulo core
```bash
rails generate devise User
```
