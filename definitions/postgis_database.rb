define :postgis_database, :action => :create do
  case params[:action]
  when :create
    postgresql_database params[:name] do
      connection params[:connection]
      owner params[:owner]
    end

    postgresql_database params[:name] do
      connection params[:connection]
      sql "CREATE EXTENSION IF NOT EXISTS postgis"
      action :query
    end

    %w(geography_columns geometry_columns raster_columns raster_overviews spatial_ref_sys).each do |table|
      postgresql_database params[:name] do
        connection params[:connection]
        sql "ALTER TABLE #{table} OWNER TO #{params[:owner]}"
        action :query
      end
    end

    postgresql_database params[:name] do
      connection params[:connection]
      sql "CREATE EXTENSION IF NOT EXISTS postgis_srs_esri_102003"
      action :query
    end
  end
end
