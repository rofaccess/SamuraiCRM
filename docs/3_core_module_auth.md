# Módulo Core (Autenticación)
## Configuración inicial
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

Generar los archivos de devise desde el módulo core
```bash
docker compose up
docker compose exec -it dev bash
rails generate devise:install
```
Esto debe generar un archivo de configuración llamado devise.rb en core/config/initializers/
Agregar las siguientes dos líneas al final del archivo mencionado.
```ruby
# SamuraiCRM/engines/core/config/initializers/devise.rb
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

Las migraciones fueron generadas dentro del módulo core. Como no es práctico ejecutar las migraciones en cadá módulo. 
Se debe configurar el módulo para que la aplicación padre busque migraciones dentro de los módulos. Para esto se debe
agregar un initalizer dentro de la clase Engine del módulo.
```ruby
# SamuraiCRM/engines/core/lib/samurai/core/engine.rb
initializer :append_migrations do |app|
  unless app.root.to_s.match(root.to_s)
    config.paths["db/migrate"].expanded.each do |p|
      app.config.paths["db/migrate"] << p
    end
  end
end
```

Se deben realizar algunos ajuste para que Devise funcione dentro de otro engine.
Se debe modificar la ruta agregada en routes.rb para que quede así
```ruby
# SamuraiCRM/engines/core/config/routes.rb
devise_for :users, class_name: "Samurai::User", module: :devise
```
class_name le indica a Devise el modelo a utilizar y el parámetro module: :devise le indica que no se está ejecutando 
dentro de una aplicación Rails regular.


Ejecutar las migraciones desde la aplicación padre
```bash
rake db:migrate
```

Generar las vistas de Devise desde el módulo Core.
```bash
rails g devise:views
```

Agregar el método para autenticar usuarios en application_controller.rb
```ruby
# core/app/controllers/samurai/application_controller.rb
module Samurai
  module Core
    class ApplicationController < ActionController::Base
      before_action :authenticate_user!
    end
  end
end
```

Reiniciar la aplicación y acceder a [localhost:3000](http://localhost:3000/). Se realizará una redirección a la vista de login.

Actualizar la vista de inicio de sesión usando Bootstrap
```erb
<!-- SamuraiCRM/engines/core/app/views/devise/sessions/new.html.erb -->
<h2>Sign in</h2><hr>
<%= form_for(resource, as: resource_name, url: session_path(resource_name),
             html: {class: 'form-horizontal'}) do |f| %>
  <div class="form-group">
    <%= f.label :email, class: "col-sm-2 control-label" %>
    <div class="col-sm-6">
      <%= f.email_field :email, autofocus: true ,
                        class: "form-control" %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :password, class: "col-sm-2 control-label" %>
    <div class="col-sm-6">
      <%= f.password_field :password, autocomplete: "off",
                           class: "form-control" %>
    </div>
  </div>
  <% if devise_mapping.rememberable? -%>
    <div class="form-group">
      <div class="col-sm-6 col-sm-offset-2">
        <%= f.check_box :remember_me %> <%= f.label :remember_me %>
      </div>
    </div>
  <% end -%>
  <div class="form-group">
    <div class="col-sm-6 col-sm-offset-2">
      <%= f.submit "Sign in", class: 'btn btn-primary' %>
    </div>
  </div>
  <div class="form-group">
    <div class="col-sm-6 col-sm-offset-2">
      <%= render "devise/shared/links" %>
    </div>
  </div>
<% end %>
```

Actualizar la vista de registro de usuario
```erb
<!-- SamuraiCRM/engines/core/app/views/devise/registrations/new.html.erb -->
<h2>Sign up</h2>
<hr>
<%= form_for(resource, as: resource_name, url: registration_path(resource_name),
             html: {class: 'form-horizontal'}) do |f| %>
  <%= devise_error_messages! %>
  <div class="form-group">
    <%= f.label :email, class: "col-sm-2 control-label" %>
    <div class="col-sm-6">
      <%= f.email_field :email, class: "form-control" %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :password, class: "col-sm-2 control-label" %>
    <div class="col-sm-6">
      <%= f.password_field :password, autocomplete: "off",
                           class: "form-control" %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :password_confirmation, class: "col-sm-2 control-label" %>
    <div class="col-sm-6">
      <%= f.password_field :password_confirmation, autocomplete: "off",
                           class: "form-control" %>
    </div>
  </div>
  <div class="form-group">
    <div class="col-sm-offset-2 col-sm-6">
      <%= f.submit "Sign up", class: "btn btn-primary" %>
    </div>
  </div>
  <div class="form-group">
    <div class="col-sm-offset-2 col-sm-6">
      <%= render "devise/shared/links" %>
    </div>
  </div>
<% end %>
```

Ahora, se procede a registrar un usuario. Si todo funciona correctamente se debería mostrar el Dashboard.

Agregar una barra de navegación al layout
```erb
<!-- SamuraiCRM/engines/core/app/views/layouts/samurai/application.html.erb -->
<!-- ... -->
<nav class="navbar navbar-inverse navbar-fixed-top">
  <div class="container">
    <div class="navbar-header">
      <%= link_to 'SamuraiCRM', samurai.root_path, class: 'navbar-brand' %>
    </div>
    <%- if current_user %>
      <div class="navbar-collapse collapse" id="navbar">
        <ul class="nav navbar-nav">
          <li>
            <%= link_to 'Home', samurai.root_path %>
          </li>
          <li>
            <%= link_to 'My Account', samurai.edit_user_registration_path %>
          </li>
          <li>
            <%= link_to 'Logout', samurai.destroy_user_session_path,
                        method: :delete %>
          </li>
        </ul>
      </div>
    <% end %>
  </div>
</nav>
<!-- ... -->
```

Actualizar la vista de edición de usuario
```erb
<!-- SamuraiCRM/engines/core/app/views/devise/registrations/edit.html.erb -->
<h2>Edit <%= resource_name.to_s.humanize %></h2>
<hr>
<%= form_for(resource, as: resource_name, url: registration_path(resource_name),
             html: { method: :put, class: 'form-horizontal' }) do |f| %>
  <%= devise_error_messages! %>
  <div class="form-group">
    <%= f.label :email, class: 'col-sm-2 control-label' %>
    <div class="col-sm-6">
      <%= f.email_field :email, class: 'form-control' %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :password, class: 'col-sm-2 control-label' %>
    <i>(leave blank if you don't want to change it)</i>
    <div class="col-sm-6">
      <%= f.password_field :password, autocomplete: "off",
                           class: 'form-control' %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :password_confirmation, class: 'col-sm-2 control-label' %>
    <div class="col-sm-6">
      <%= f.password_field :password_confirmation, autocomplete: "off",
                           class: 'form-control' %>
    </div>
  </div>
  <div class="form-group">
    <%= f.label :current_password, class: 'col-sm-2 control-label' %>
    <i>(we need your current password to confirm your changes)</i>
    <div class="col-sm-6">
      <%= f.password_field :current_password, autocomplete: "off",
                           class: 'form-control' %>
    </div>
  </div>
  <div class="form-group">
    <div class="col-sm-offset-2 col-sm-6">
      <%= f.submit "Update", class: "btn btn-primary" %>
    </div>
  </div>
<% end %>
<h2>Cancel my account</h2>
<hr>
<p>Unhappy?
  <%= button_to "Cancel my account", registration_path(resource_name),
                data: { confirm: "Are you sure?" },
                method: :delete,
                class: 'btn btn-danger' %></p>
<hr>
<%= link_to "Back", :back, class: 'btn btn-default' %>
```

Agregar un helper para indicar en el menú que página se está viendo actualmente
```ruby
# SamuraiCRM/engines/core/app/helpers/samurai/application_helper.rb
def active(path)
  current_page?(path) ? 'active' : ''
end
```

Usar este helper en el navbar
```erb
<!-- SamuraiCRM/engines/core/app/views/layouts/samurai/application.html.erb -->
<!-- ... -->
<ul class="nav navbar-nav">
    <li class="<%= active(samurai.root_path) %>">
    <%= link_to 'Home', samurai.root_path %>
                </li>
                <li class="<%= active(samurai.edit_user_registration_path) %>">
    <%= link_to 'My Account', samurai.edit_user_registration_path %>
                </li>
                <li>
                  <%= link_to 'Logout', samurai.destroy_user_session_path, method: :delete %>
    </li>
</ul>
<!-- ... -->
```
