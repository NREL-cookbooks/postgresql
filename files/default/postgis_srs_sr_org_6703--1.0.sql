DO $$
  BEGIN
    IF NOT EXISTS(SELECT srid FROM spatial_ref_sys WHERE srid = 96703) THEN
      INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 96703, 'sr-org', 6703, '', 'PROJCS["USA_Contiguous_Albers_Equal_Area_Conic_USGS_version",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Albers"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-96.0],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["Latitude_Of_Origin",23.0],UNIT["Meter",1.0]]');
    END IF;
  END
$$;
