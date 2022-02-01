--We cannot move the einzelstimmen indices here as this would cause massive performance issues
DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis;
DROP INDEX IF EXISTS ungueltige_stimme_stimmentyp;
DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis_stimmentyp;

CREATE INDEX ungueltige_stimme_wahlkreis ON ungueltige_stimme (wahlkreis);
CREATE INDEX ungueltige_stimme_stimmentyp ON ungueltige_stimme (stimmentyp);
CREATE INDEX ungueltige_stimme_wahlkreis_stimmentyp ON ungueltige_stimme (stimmentyp, wahlkreis);