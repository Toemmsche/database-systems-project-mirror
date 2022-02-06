DROP INDEX IF EXISTS erststimme_kandidatur;

DROP INDEX IF EXISTS zweitstimme_wahlkreis;
DROP INDEX IF EXISTS zweitstimme_liste;
DROP INDEX IF EXISTS zweitstimme_wahlkreis_liste;

DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis;
DROP INDEX IF EXISTS ungueltige_stimme_stimmentyp;
DROP INDEX IF EXISTS ungueltige_stimme_wahlkreis_stimmentyp;


CREATE INDEX erststimme_kandidatur ON erststimme (kandidatur);

CREATE INDEX zweitstimme_wahlkreis ON zweitstimme (wahlkreis);
CREATE INDEX zweitstimme_liste ON zweitstimme (liste);
CREATE INDEX zweitstimme_wahlkreis_liste ON zweitstimme (wahlkreis, liste);

CREATE INDEX ungueltige_stimme_wahlkreis ON ungueltige_stimme (wahlkreis);
CREATE INDEX ungueltige_stimme_stimmentyp ON ungueltige_stimme (stimmentyp);
CREATE INDEX ungueltige_stimme_wahlkreis_stimmentyp ON ungueltige_stimme (stimmentyp, wahlkreis);

DROP INDEX IF EXISTS zweitstimmmenergebnis_wahlkreis;
DROP INDEX IF EXISTS direktkandidatur_wahlkreis;

CREATE INDEX zweitstimmenergebnis_wahlkreis ON zweitstimmenergebnis (wahlkreis);
CREATE INDEX direktkandidatur_wahlkreis ON direktkandidatur (wahlkreis);