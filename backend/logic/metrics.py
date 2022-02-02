import json

import psycopg

from logic.util import table_to_json


def get_wahlkreise_ranked_by_metric(
        cursor: psycopg.Cursor,
        wahl: int,
        metric: str
) -> str:
    query = (f"""
        SELECT wk.wkid, wk.nummer, sd.{metric} AS metrik_wert, ROW_NUMBER() 
        OVER (ORDER BY sd.{metric}) AS rank 
        FROM wahlkreis wk, strukturdaten sd 
        WHERE wahl = {wahl} AND wk.wkid = sd.wahlkreis
    """)

    # misuse table_to_json
    return table_to_json(cursor, "", query=query)


def valid_metrik(metrik: str):
    return metrik.lower() in [value["db"] for value in sd_mapping.values()]


def all_metrics_to_json(wahl: int):
    metrics = [{"metrik": value["db"], "displayName": key} for key, value in sd_mapping.items() if wahl in value]
    return json.dumps(metrics, ensure_ascii=False)


sd_mapping = {
    'Ausländeranteil': {
        20: 'Bevölkerung am 31.12.2019 - Ausländer/-innen (%)',
        19: 'Bevölkerung am 31.12.2015 - Ausländer (%)',
        "db": 'auslaenderanteil'
    },
    'Bevölkerungsdichte': {
        20: 'Bevölkerungsdichte am 31.12.2019 (EW je km²)',
        19: 'Bevölkerungsdichte am 31.12.2015 (Einwohner je km²)',
        "db": 'bevoelkerungsdichte'
    },
    'Wanderungssaldo pro 1000 Einwohner': {
        20: 'Zu- (+) bzw. Abnahme (-) der Bevölkerung 2019 - Wanderungssaldo '
            '(je 1000 EW)',
        19: 'Zu- (+) bzw. Abnahme (-) der Bevölkerung 2015 - Wanderungssaldo '
            '(je 1000 Einwohner)',
        "db": 'bevoelkerungsveraenderung_pro_1000_ew',
    },
    'Altersanteil unter 18': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - unter 18 (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - unter 18 (%)',
        "db": 'altersanteil_unter_18',
    },
    'Altersanteil 18-24': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - 18-24 (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - 18-24 (%)',
        "db": 'altersanteil_18_bis_24'
    },
    'Altersanteil 25-34': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - 25-34 (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - 25-34 (%)',
        "db": 'altersanteil_25_bis_34'
    },
    'Altersanteil 35-59': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - 35-59 (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - 35-59 (%)',
        "db": 'altersanteil_35_bis_59'
    },
    'Altersanteil 60-74': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - 60-74 (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - 60-74 (%)',
        "db": 'altersanteil_60_bis_74'
    },
    'Alter über 74': {
        20: 'Alter von ... bis ... Jahren am 31.12.2019 - 75 und mehr (%)',
        19: 'Alter von ... bis ... Jahren am 31.12.2015 - 75 und mehr (%)',
        "db": 'altersanteil_ueber_74'
    },
    'Bodenflächenanteil Siedlung/Verkehr': {
        20: 'Bodenfläche nach Art der tatsächlichen Nutzung am 31.12.2019 - '
            'Siedlung und Verkehr (%)',
        "db": 'bodenflaechenanteil_siedlung_verkehr'
    },
    'Bodenflächenanteil Vegatation/Gewässer': {
        20: 'Bodenfläche nach Art der tatsächlichen Nutzung am 31.12.2019 - '
            'Vegetation und Gewässer (%)',
        "db": 'bodenflaechenanteil_vegation_gewaesser'
    },
    'Wohnungen pro 1000 Einwohner': {
        20: 'Bestand an Wohnungen am 31.12.2019 - insgesamt (je 1000 EW)',
        19: 'Bautätigkeit und Wohnungswesen - Bestand an Wohnungen am '
            '31.12.2015 (je 1000 Einwohner)',
        "db": 'wohnungen_pro_1000_ew',
    },
    'Durchschnittliche Wohnfläche pro Wohnung': {
        20: 'Wohnfläche am 31.12.2019 (je Wohnung)',
        "db": 'wohnflaeche_pro_wohnung'
    },
    'Durchschnittliche Wohnfläche pro Einwohner': {
        20: 'Wohnfläche am 31.12.2019 (je EW)',
        "db": 'wohnflaeche_pro_einwohner'
    },
    'PKW-Bestand pro 1000 Einwohner': {
        20: 'PKW-Bestand am 01.01.2020 - PKW insgesamt (je 1000 EW)',
        19: 'Kraftfahrzeugbestand am 01.01.2016 (je 1000 Einwohner)',
        "db": 'pkw_bestand_pro_1000_ew'
    },
    'PKW-Anteil Elektro/Hybrid': {
        20: 'PKW-Bestand am 01.01.2020 - PKW mit Elektro- oder Hybrid-Antrieb '
            '(%)',
        "db": 'pkw_anteil_elektro_hybrid',
    },
    'Unternehmen pro 1000 Einwohner': {
        20: 'Unternehmensregister 2018 - Unternehmen insgesamt (je 1000 EW)',
        19: 'Unternehmensregister 2014 - Unternehmen insgesamt (je 1000 '
            'Einwohner)',
        "db": 'unternehmen_pro_1000_ew'
    },
    'Handwerksunternehmen pro 1000 Einwohner': {
        20: 'Unternehmensregister 2018 - Handwerksunternehmen (je 1000 EW)',
        19: 'Unternehmensregister 2014 - Handwerksunternehmen (je 1000 '
            'Einwohner)',
        "db": 'handwerksunternehmen_pro_1000_ew'
    },
    'Schulabänger beruflicher Schulen pro 1000 Einwohner': {
        20: 'Schulabgänger/-innen beruflicher Schulen 2019',
        19: 'Absolventen/Abgänger beruflicher Schulen 2015',
        "db": 'schulabgaenger_beruflich_pro_1000_ew',
    },
    'Schulabänger mit Allgemeinbildung pro 1000 Einwohner': {
        20: 'Schulabgänger/-innen allgemeinbildender Schulen 2019 - insgesamt '
            'ohne Externe (je 1000 EW)',
        19: 'Absolventen/Abgänger allgemeinbildender Schulen 2015 - insgesamt '
            'ohne Externe (je 1000 Einwohner)',
        "db": 'schulabgaenger_allgemeinbildend_pro_1000_ew',
    },
    'Anteil Schulabgänger mit Allgemeinbildung ohne Hauptschulabschluss': {
        20: 'Schulabgänger/-innen allgemeinbildender Schulen 2019 - ohne '
            'Hauptschulabschluss (%)',
        19: 'Absolventen/Abgänger allgemeinbildender Schulen 2015 - ohne '
            'Hauptschulabschluss (%)',
        "db": 'schulabgaengeranteil_allgemeinbildend_ohne_hauptschulabschluss'
    },
    'Anteil Schulabgänger mit Hauptschulabschluss': {
        20: 'Schulabgänger/-innen allgemeinbildender Schulen 2019 - mit '
            'Hauptschulabschluss (%)',
        19: 'Absolventen/Abgänger allgemeinbildender Schulen 2015 - mit '
            'Hauptschulabschluss (%)',
        "db": 'schulabgaengeranteil_allgemeinbildend_hauptschulabschluss'
    },
    'Anteil Schulabgänger mit Mittlerer Reife': {
        20: 'Schulabgänger/-innen allgemeinblldender Schulen 2019 - mit '
            'allgemeiner und Fachhochschulreife (%)',
        19: 'Absolventen/Abgänger allgemeinbildender Schulen 2015 - mit '
            'allgemeiner und Fachhochschulreife (%)',
        "db": 'schulabgaengeranteil_allgemeinbildend_mittlerer_schulabschluss'
    },
    'Anteil Schulabgänger mit Hochschulreife': {
        20: 'Schulabgänger/-innen allgemeinbildender Schulen 2019 - ohne '
            'Hauptschulabschluss (%)',
        19: 'Absolventen/Abgänger allgemeinbildender Schulen 2015 - ohne '
            'Hauptschulabschluss (%)',
        "db": 'schulabgaengeranteil_allgemeinbildend_hochschulreife'
    },
    'Einkommen pro Einwohner (€)': {
        20: 'Verfügbares Einkommen der privaten Haushalte 2018 (EUR je EW)',
        19: 'Verfügbares Einkommen der privaten Haushalte 2014 (€ je '
            'Einwohner)',
        "db": 'einkommen_pro_ew'
    },
    'Bruttoinlandsprodukt pro Einwohner': {
        20: 'Bruttoinlandsprodukt 2018 (EUR je EW)',
        19: 'Bruttoinlandsprodukt 2014 (€ je Einwohner)',
        "db": 'bip_pro_ew'
    },
    'Beschäftigte pro 1000 Einwohner': {
        20: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2020 - '
            'insgesamt (je 1000 EW)',
        19: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2016 - '
            'insgesamt (je 1000 Einwohner)',
        "db": 'beschaeftigte_pro_1000_ew'
    },
    'Beschäftigtenanteil in Land- und Forstwirtschaft': {
        20: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2020 - Land- '
            'und Forstwirtschaft, Fischerei (%)',
        19: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2016 - Land- '
            'und Forstwirtschaft, Fischerei (%)',
        "db": 'beschaeftigtenanteil_landwirtschaft_forstwirtschaft_fischerei'
    },
    'Beschäftigtenanteil im produzierenden Gewerbe': {
        20: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2020 - '
            'Produzierendes Gewerbe (%)',
        19: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2016 - '
            'Produzierendes Gewerbe (%)',
        "db": 'beschaeftigtenanteil_produzierendes_gewerbe'
    },
    'Beschäftigtenanteil in Handel, Gastgewerbe, und Verkehr': {
        20: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2020 - '
            'Handel, Gastgewerbe, Verkehr (%)',
        19: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2016 - '
            'Handel, Gastgewerbe, Verkehr (%)',
        "db": 'beschaeftigtenanteil_handel_gastgewerbe_verkehr'
    },
    'Beschäftigtenanteil im Dienstleistungsgewerbe': {
        20: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2020 - '
            'Öffentliche und private Dienstleister (%)',
        19: 'Sozialversicherungspflichtig Beschäftigte am 30.06.2016 - '
            'Öffentliche und private Dienstleister (%)',
        "db": 'beschaeftigtenanteil_dienstleister'
    },
    'Leistungsempfänger pro 1000 Einwohner': {
        20: 'Empfänger/-innen von Leistungen nach SGB II  Oktober 2020 -  '
            'insgesamt (je 1000 EW)',
        19: 'Empfänger(innen) von Leistungen nach SGB II am 31.12.2016 -  '
            'insgesamt (je 1000 Einwohner)',
        "db": 'leistungsempfaenger_pro_1000_ew'
    },
    'Arbeitslosenquote': {
        20: 'Arbeitslosenquote Februar 2021 - insgesamt',
        19: 'Arbeitslosenquote März 2017 - insgesamt',
        "db": 'arbeitslosenquote'
    },
    'Arbeitslosenquote Männer': {
        20: 'Arbeitslosenquote Februar 2021 - Männer',
        19: 'Arbeitslosenquote März 2017 - Männer',
        "db": 'arbeitslosenquote_maenner'
    },
    'Arbeitslosenquote Frauen': {
        20: 'Arbeitslosenquote Februar 2021 - Frauen',
        19: 'Arbeitslosenquote März 2017 - Frauen',
        "db": 'arbeitslosenquote_frauen'
    },
    'Arbeitslosenquote 15 bis 24 Jahre': {
        20: 'Arbeitslosenquote Februar 2021 - 15 bis 24 Jahre',
        "db": 'arbeitslosenquote_15_bis_24'
    },
    'Arbeitslosenquote 55 bis 64 Jahre': {
        20: 'Arbeitslosenquote Februar 2021 - 55 bis 64 Jahre',
        19: 'Arbeitslosenquote März 2017 - 55 bis unter 65 Jahre',
        "db": 'arbeitslosenquote_55_bis_64'
    }
}
