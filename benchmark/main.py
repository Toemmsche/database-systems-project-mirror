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
    wait_time = between(0.8, 1.2)
    host = "http://localhost:5000"

    # Q1
    @task(25)
    def query_sitzverteilung(self):
        self.query_random_wahlen(["/api/{wahl}/sitzverteilung"])

    # Q2
    @task(10)
    def query_mdb(self):
        wahl = random_wahl()
        self.query_random_wahlen([f"/api/{wahl}/mdb"])

    # Q3
    @task(25)
    def query_wahlkreisuebersicht(self):
        wahlkreis = random_wahlkreis()
        self.query_random_wahlen(
            [f"/api/{{wahl}}/wahlkreis/{wahlkreis}", f"/api/{{wahl}}/wahlkreis/{wahlkreis}/erststimmen", f"/api/{{wahl}}/wahlkreis/{wahlkreis}/zweitstimmen"])

    # Q4
    @task(10)
    def query_stimmkreissieger(self):
        self.query_random_wahlen(["/api/{wahl}/wahlkreissieger"])

    # Q5
    @task(10)
    def query_ueberhang(self):
        self.query_random_wahlen(["/api/{wahl}/ueberhang"])

    # Q6
    @task(20)
    def query_knappste_sieger(self):
        self.query_random_wahlen(["/api/{wahl}/stat/knapp"])

    def query_random_wahlen(self, requests: list[str]):
        wahlen = random_wahlen()
        for wahl in wahlen:
            for request in requests:
                self.client.get(request.format(wahl=wahl))
