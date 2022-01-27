DROP FUNCTION IF EXISTS metrik_rang(wahl int, column_name text);

CREATE FUNCTION metrik_rang(wahl int, column_name text)
    RETURNS TABLE(wkid int, nummer int, metrik decimal, rank bigint)
AS
$$
begin
  return query execute format('SELECT wk.wkid, wk.nummer, sd.%I AS metrik, ROW_NUMBER() OVER (ORDER BY sd.%I) AS rank ' ||
                 'FROM wahlkreis wk, strukturdaten sd ' ||
                 'WHERE wahl = $1 AND wk.wkid = sd.wahlkreis', column_name, column_name)
     using wahl;
end;
$$
LANGUAGE plpgsql;