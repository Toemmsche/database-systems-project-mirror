/*
 TODO: Aufteilung von Überhangsmandaten, die nicht ausgeglichen werden auf Länder (beeinflusst Ergebnis nicht, da CSU nur in einem Land)
 TODO: Einzelstimmen verwenden statt aggregierte Werte
 */
with recursive
    direktkandidaturen_2021 as
        (select dk.direktid,
                dk.wahlkreis,
                dk.kandidat,
                dk.anzahlStimmen,
                wk.land,
                dk.partei
         from direktkandidatur dk,
              wahlkreis wk
         where dk.wahl = 20
           and wk.wkid = dk.wahlkreis), -- Was passiert bei Stimmengleichheit?
    gewinner_direktmandate_2021 as
        (select dk1.direktid,
                dk1.wahlkreis,
                dk1.kandidat,
                dk1.land,
                dk1.partei
         from direktkandidaturen_2021 dk1
         where not exists
             (select *
              from direktkandidaturen_2021 dk2
              where dk1.anzahlStimmen <= dk2.anzahlStimmen
                and dk1.wahlkreis = dk2.wahlkreis
                and dk1.direktid != dk2.direktid)),
    direktmandate_2021 as
        (select dk.partei,
                count(*) as anzahl
         from gewinner_direktmandate_2021 g,
              direktkandidatur dk
         where g.direktid = dk.direktid
         group by dk.partei),
    direktmandate_2021_land as
        (select dk.partei,
                g.land,
                count(*) as anzahl
         from gewinner_direktmandate_2021 g,
              direktkandidatur dk
         where g.direktid = dk.direktid
         group by dk.partei,
                  g.land),
    deutsche(land, deutsche) as (
        values (1,
                2659792),
               (2,
                1537766),
               (3,
                7207587),
               (4,
                548941),
               (5,
                15415642),
               (6,
                5222158),
               (7,
                3610865),
               (8,
                9313413),
               (9,
                11328866),
               (10,
                865191),
               (11,
                2942960),
               (12,
                2397701),
               (13,
                1532412),
               (14,
                3826905),
               (15,
                2056177),
               (16,
                1996822)),              --     deutsche as (
--         select wk.land, bl.name, sum(wk.deutsche) as deutsche
--         from wahlkreis wk,
--              bundesland bl
--         where wahl = 20
--           and wk.land = bl.landid
--         group by wk.land, bl.name
--     ),
    anzahl_deutsche as
        (select sum(d.deutsche) as deutsche
         from deutsche d),
    sitzverteilung as
        (select sum(round(d.deutsche / (
                (select *
                 from anzahl_deutsche)::numeric / 598))) as sitze,
                sum(d.deutsche)::numeric / 598           as divisor,
                sum(d.deutsche)::numeric / 598           as next_divisor
         from deutsche d
         union all
         (select (select sum(round(d.deutsche / sv.next_divisor))
                  from deutsche d) as sitze,
                 sv.next_divisor,
                 case
                     when sitze < 598 then
                         (select avg(d.divisor)
                          from (select d.deutsche / (round(d.deutsche / sv.next_divisor) + 0.5 + dk.divisor) as divisor
                                from deutsche d,
                                     divisor_kandidaten dk
                                order by divisor desc
                                limit 2) as d)
                     when sitze > 598 then
                         (select avg(d.divisor)
                          from (select d.deutsche / (round(d.deutsche / sv.next_divisor) - 0.5 - dk.divisor) as divisor
                                from deutsche d,
                                     divisor_kandidaten dk
                                order by divisor
                                limit 2) as d)
                     else sv.next_divisor
                     end
          from sitzverteilung sv
          where sitze != 598)),
    divisor as
        (select *
         from sitzverteilung
         where sitze = 598),
    sitzverteilung_laender as
        (select de.land,
                round(de.deutsche / di.divisor) as sitze
         from deutsche de,
              divisor di
         order by de.land),
    zweitstimmen as
        (select l.listenid,
                l.land,
                l.partei,
                sum(zse.anzahlstimmen) as anzahlStimmen
         from zweitstimmenergebnis zse,
              landesliste l
         where l.listenid = zse.liste
           and l.wahl = 20
         group by l.listenid,
                  l.land,
                  l.partei),
    zweitstimmen_parteien as
        (select l.partei,
                sum(zs.anzahlStimmen) as anzahlStimmen
         from zweitstimmen zs,
              landesliste l
         where zs.listenid = l.listenid
         group by l.partei),
    parteien_fuenf_prozent as
        (select zsp.partei
         from zweitstimmen_parteien zsp
         where zsp.anzahlStimmen >= 0.05 *
                                    (select sum(zsp.anzahlStimmen)
                                     from zweitstimmen_parteien zsp)),
    zweitstimmen_gefiltert as
        (select zs.*
         from zweitstimmen zs,
              partei p
         where zs.partei = p.parteiid
           and (p.nationaleminderheit = 1::bit
             or zs.partei in
                (select *
                 from parteien_fuenf_prozent)
             or exists
                    (select *
                     from direktmandate_2021 dm
                     where dm.partei = zs.partei
                       and dm.anzahl >= 3))),
    zweitstimmen_parteien_gefiltert as
        (select *
         from zweitstimmen_parteien zsp
         where exists
                   (select *
                    from zweitstimmen_gefiltert zs
                    where zs.partei = zsp.partei)),
    zweitstimmen_land as
        (select zs.land,
                sum(zs.anzahlStimmen) as anzahlStimmen
         from zweitstimmen_gefiltert zs
         group by zs.land),
    laender_divisor as
        (select zsl.land                                                                as land,
                sum(round(zs.anzahlStimmen / (zsl.anzahlStimmen::numeric / svl.sitze))) as sitze2,
                zsl.anzahlStimmen::numeric / svl.sitze                                  as divisor,
                zsl.anzahlStimmen::numeric / svl.sitze                                  as next_divisor
         from zweitstimmen_gefiltert zs,
              zweitstimmen_land zsl,
              sitzverteilung_laender svl
         where zs.land = zsl.land
           and zsl.land = svl.land
         group by zsl.land,
                  zsl.anzahlStimmen,
                  svl.sitze
         union all
         (select zsl.land,

                 (select sum(round(zs.anzahlStimmen / ld.next_divisor))
                  from zweitstimmen_gefiltert zs
                  where zs.land = zsl.land) as sitze,
                 ld.next_divisor,
                 case
                     when sitze < ld.sitze2 then
                         (select avg(d.divisor)
                          from (select zs.anzahlStimmen /
                                       (round(zs.anzahlStimmen / ld.next_divisor) - 0.5 - dk.divisor) as divisor
                                from divisor_kandidaten dk,
                                     zweitstimmen_gefiltert zs
                                where zs.land = zsl.land
                                  and round(zs.anzahlStimmen / ld.next_divisor) > dk.divisor
                                order by divisor
                                limit 2) as d)
                     when sitze > ld.sitze2 then
                         (select avg(d.divisor)
                          from (select zs.anzahlStimmen /
                                       (round(zs.anzahlStimmen / ld.next_divisor) + 0.5 + dk.divisor) as divisor
                                from divisor_kandidaten dk,
                                     zweitstimmen_gefiltert zs
                                where zs.land = zsl.land
                                order by divisor desc
                                limit 2) as d)
                     else ld.next_divisor
                     end
          from zweitstimmen_land zsl,
               laender_divisor ld,
               sitzverteilung_laender svl
          where zsl.land = ld.land
            and zsl.land = svl.land
            and sitze != ld.sitze2)),
    sitzverteilung_parteien as
        (select zs.land,
                zs.partei,
                round(zs.anzahlStimmen / ld.divisor) as sitze
         from laender_divisor ld,
              zweitstimmen_gefiltert zs,
              sitzverteilung_laender svl
         where ld.land = zs.land
           and zs.land = svl.land
           and svl.sitze = ld.sitze2),
    mindestsitzanspruch_parteien_land as
        (select coalesce(dm.land, svp.land)     as land,
                coalesce(dm.partei, svp.partei) as partei,
                coalesce(svp.sitze, 0)          as MinZweitstimmenMandate,
                coalesce(dm.anzahl, 0)          as MinErststimmenMandate
         from (sitzverteilung_parteien svp
                  full outer join direktmandate_2021_land dm on svp.partei = dm.partei
             and svp.land = dm.land)),
    mindestsitzanspruch_parteien_land2 as
        (select mpl.partei,
                sum(mpl.MinZweitstimmenMandate) as SitzeNachSitzkontingenten,
                sum(case
                        when mpl.MinErststimmenMandate > mpl.MinZweitstimmenMandate
                            then mpl.MinErststimmenMandate - mpl.MinZweitstimmenMandate
                        else 0
                    end)                        as DrohenderUeberhang,
                sum(case
                        when round((mpl.MinErststimmenMandate + mpl.MinZweitstimmenMandate) / 2) >
                             mpl.MinErststimmenMandate
                            then round((mpl.MinErststimmenMandate + mpl.MinZweitstimmenMandate) / 2)
                        else mpl.MinErststimmenMandate
                    end)                        as Mindestsitzzahl
         from mindestsitzanspruch_parteien_land mpl
         group by mpl.partei),
    mindestsitzanspruch_parteien_land3 as
        (select mpl.partei,
                mpl.land,
                mpl.MinZweitstimmenMandate as SitzeNachSitzkontingenten,
                case
                    when mpl.MinErststimmenMandate > mpl.MinZweitstimmenMandate
                        then mpl.MinErststimmenMandate - mpl.MinZweitstimmenMandate
                    else 0
                    end                    as DrohenderUeberhang,
                case
                    when round((mpl.MinErststimmenMandate + mpl.MinZweitstimmenMandate) / 2) > mpl.MinErststimmenMandate
                        then round((mpl.MinErststimmenMandate + mpl.MinZweitstimmenMandate) / 2)
                    else mpl.MinErststimmenMandate
                    end                    as Mindestsitzzahl
         from mindestsitzanspruch_parteien_land mpl),
    mindestsitzanspruch_parteien as
        (select mpl.partei,
                mpl.SitzeNachSitzkontingenten,
                (case
                     when mpl.SitzeNachSitzkontingenten > mpl.Mindestsitzzahl then mpl.SitzeNachSitzkontingenten
                     else mpl.Mindestsitzzahl
                    end) as Mindestsitzanspruch,
                mpl.DrohenderUeberhang,
                zsp.anzahlStimmen
         from mindestsitzanspruch_parteien_land2 mpl,
              zweitstimmen_parteien zsp
         where zsp.partei = mpl.partei),
    kleinster_parteien_divisor_ohne_ueberhang as (
        (select mp.anzahlStimmen / (mp.SitzeNachSitzkontingenten - 0.5) as ParteiDivisor
         from mindestsitzanspruch_parteien mp
         order by ParteiDivisor
         limit 1)),
    ueberhang(ueberhang) as (
        values (0), (1), (2), (3)),
    viertkleinster_parteien_divisor_mit_ueberhang as (
        (select mp.anzahlStimmen / (mp.Mindestsitzanspruch - u.ueberhang - 0.5) as ParteiDivisor
         from mindestsitzanspruch_parteien mp,
              ueberhang u
         where mp.DrohenderUeberhang >= u.ueberhang
         order by ParteiDivisor
         limit 1 offset 3)),
    obergrenze_divisorspanne as
        (select case
                    when d1.ParteiDivisor < d2.ParteiDivisor then d1.ParteiDivisor
                    else d2.ParteiDivisor
                    end as Obergrenze
         from kleinster_parteien_divisor_ohne_ueberhang d1,
              viertkleinster_parteien_divisor_mit_ueberhang d2),
    untergrenze_divisorspanne as
        (select zpg.anzahlStimmen / (round(zpg.anzahlStimmen / d.Obergrenze) + 0.5) as Untergrenze
         from zweitstimmen_parteien_gefiltert zpg,
              obergrenze_divisorspanne d
         order by Untergrenze desc
         limit 1),
    endgueltiger_divisor as
        (select (u.Untergrenze + o.Obergrenze) / 2 as divisor
         from untergrenze_divisorspanne u,
              obergrenze_divisorspanne o),
    sitze_nach_erhoehung as
        (select zpg.partei,
                (case
                     when round(zpg.anzahlStimmen / d.divisor) > mp.Mindestsitzanspruch
                         then round(zpg.anzahlStimmen / d.divisor)
                     else mp.Mindestsitzanspruch
                    end) as sitze
         from zweitstimmen_parteien_gefiltert zpg,
              endgueltiger_divisor d,
              mindestsitzanspruch_parteien mp
         where mp.partei = zpg.partei),
    divisor_kandidaten(divisor) as (
        values (0), (1)),
    landeslisten_divisor as (
        (select zsl.partei,
                sum(case
                        when round(zs.anzahlStimmen / (zsl.anzahlStimmen::numeric / svl.sitze)) > mp.mindestsitzzahl
                            then round(zs.anzahlStimmen / (zsl.anzahlStimmen::numeric / svl.sitze))
                        else mp.mindestsitzzahl
                    end)                               as sitze2,
                zsl.anzahlStimmen::numeric / svl.sitze as divisor,
                zsl.anzahlStimmen::numeric / svl.sitze as next_divisor
         from zweitstimmen_gefiltert zs,
              zweitstimmen_parteien_gefiltert zsl,
              sitze_nach_erhoehung svl,
              mindestsitzanspruch_parteien_land3 mp
         where zs.partei = zsl.partei
           and zsl.partei = svl.partei
           and mp.partei = zsl.partei
           and mp.land = zs.land
         group by zsl.partei,
                  zsl.anzahlStimmen,
                  svl.sitze)
        union all
        (select ld.partei,
                (select sum(case
                                when round(zs.anzahlStimmen / ld.next_divisor) > mp.mindestsitzzahl
                                    then round(zs.anzahlStimmen / ld.next_divisor)
                                else mp.mindestsitzzahl
                    end)
                 from mindestsitzanspruch_parteien_land3 mp,
                      zweitstimmen_gefiltert zs
                 where zs.land = mp.land
                   and zs.partei = mp.partei
                   and zs.partei = ld.partei),
                ld.next_divisor,
                (case
                     when ld.sitze2 > svl.sitze then
                         (select avg(dk.divisor)
                          from (select zs.anzahlStimmen /
                                       (round(zs.anzahlStimmen / ld.next_divisor) - dk.divisor - 0.5) as divisor
                                from zweitstimmen_gefiltert zs,
                                     divisor_kandidaten dk,
                                     mindestsitzanspruch_parteien_land3 mp
                                where zs.partei = ld.partei
                                  and mp.partei = zs.partei
                                  and mp.land = zs.land
                                  and round(zs.anzahlStimmen / ld.next_divisor) - mp.mindestsitzzahl > dk.divisor
                                order by divisor
                                limit 2) as dk)
                     when ld.sitze2 < svl.sitze then
                         (select avg(dk.divisor)
                          from (select zs.anzahlStimmen /
                                       (round(zs.anzahlStimmen / ld.next_divisor) + dk.divisor + 0.5) as divisor
                                from zweitstimmen_gefiltert zs,
                                     divisor_kandidaten dk
                                where zs.partei = ld.partei
                                order by divisor desc
                                limit 2) as dk)
                     else ld.next_divisor
                    end)
         from landeslisten_divisor ld,
              sitze_nach_erhoehung svl
         where ld.partei = svl.partei
           and ld.sitze2 != svl.sitze)),
    verteilung_landeslisten as
        (select zg.partei,
                zg.land,
                (case
                     when round(zg.anzahlStimmen / d.divisor) > mp.mindestsitzzahl
                         then round(zg.anzahlStimmen / d.divisor)
                     else mp.mindestsitzzahl
                    end) as sitze
         from landeslisten_divisor d,
              sitze_nach_erhoehung svl,
              zweitstimmen_gefiltert zg,
              mindestsitzanspruch_parteien_land3 mp
         where svl.sitze = d.sitze2
           and d.partei = svl.partei
           and zg.partei = svl.partei
           and zg.partei = mp.partei
           and zg.land = mp.land),
    verbleibende_landeslistensitze as
        (select vl.partei,
                vl.land,
                vl.sitze - coalesce(dl.anzahl, 0) as verbleibend
         from verteilung_landeslisten vl
                  left outer join direktmandate_2021_land dl on (vl.land = dl.land
             and vl.partei = dl.partei)),
    landeslisten_ohne_gewinner as
        (select l.listenid,
                l.partei,
                l.land,
                lp.position,
                lp.kandidat
         from listenplatz lp,
              landesliste l
         where lp.liste = l.listenid
           and l.wahl = 20
           and lp.kandidat not in
               (select gd.kandidat
                from gewinner_direktmandate_2021 gd)),
    landeslisten_mandate as
        (select log1.listenid,
                log1.position,
                log1.kandidat,
                log1.land,
                log1.partei
         from landeslisten_ohne_gewinner log1,
              verbleibende_landeslistensitze vl
         where log1.land = vl.land
           and log1.partei = vl.partei
           and (select count(*)
                from landeslisten_ohne_gewinner log2
                where log1.partei = log2.partei
                  and log1.land = log2.land
                  and log2.position < log1.position) < vl.verbleibend)
    (select k.vorname,
            k.nachname,
            'Direktmandat aus Wahlkreis ' || wk.nummer || ' - ' || wk.name as Grund,
            p.kuerzel
     from kandidat k,
          gewinner_direktmandate_2021 gd,
          wahlkreis wk,
          partei p
     where k.kandid = gd.kandidat
       and gd.wahlkreis = wk.wkid
       and wk.wahl = 20
       and gd.partei = p.parteiid)
union
(select k.vorname,
        k.nachname,
        'Landeslistenmandat von Listenplatz ' || lm.position || ' in ' || bl.name as Grund,
        p.kuerzel
 from kandidat k,
      landeslisten_mandate lm,
      bundesland bl,
      partei p
 where k.kandid = lm.kandidat
   and lm.land = bl.landid
   and lm.partei = p.parteiid)