from locust import HttpUser, task, between
from random import *


def random_wahl() -> int:
    wahlen = [19, 20]
    return sample(wahlen, 1)[0]


def random_wahlen() -> list[int]:
    """
    with 50% comparison between 2017 and 2021
    with 25% each for 2017 and 2021
    """
    wahlen = [19, 20]
    count = randint(1, 2)
    return list(sample(wahlen, count))


def random_wahlkreis() -> int:
    return randint(1, 299)


class WahlUser(HttpUser):
    t = 0.1  # average wait time in seconds
    wait_time = between(0.8 * t, 1.2 * t)
    host = "http://localhost:3000"

    # Q1
    @task(25)
    def query_sitzverteilung(self):
        self.query_random_wahlen(["/sitzverteilung?wahl=eq.{wahl}"])

    # Q2
    @task(10)
    def query_mdb(self):
        wahl = random_wahl()
        self.query_random_wahlen([f"/mitglieder_bundestag?wahl=eq.{wahl}"])

    # Q3
    @task(25)
    def query_wahlkreisuebersicht(self):
        wahlkreis = 222
        self.query_random_wahlen(
            [f"/wahlkreisinformation?wk_nummer=eq.{wahlkreis}&wahl=eq.{{wahl}}",
             f"/stimmen_qpartei_wahlkreis?wk_nummer=eq.{wahlkreis}&wahl=eq.{{wahl}}"])

    # Q4
    @task(10)
    def query_stimmkreissieger(self):
        self.query_random_wahlen(["/wahlkreissieger?wahl=eq.{wahl}"])

    # Q5
    @task(10)
    def query_ueberhang(self):
        self.query_random_wahlen(["/ueberhang_qpartei_bundesland?wahl=eq.{wahl}"])

    # Q6
    @task(20)
    def query_knappste_sieger(self):
        self.query_random_wahlen(["/knappste_siege_oder_niederlagen?wahl=eq.{wahl}"])

    def query_random_wahlen(self, requests: list[str]):
        wahlen = random_wahlen()
        for wahl in wahlen:
            for request in requests:
                self.client.get(request.format(wahl=wahl))
