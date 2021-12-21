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
    t = 1 # average wait time in seconds
    wait_time = between(0.8 * t, 1.2 * t)
    host = "http://localhost:5000"

    # Q1
    @task(100)
    def query_sitzverteilung(self):
        self.query_random_wahlen(["/api/{wahl}/sitzverteilung"])

    def query_random_wahlen(self, requests: list[str]):
        wahlen = random_wahlen()
        for wahl in wahlen:
            for request in requests:
                self.client.get(request.format(wahl=wahl))
