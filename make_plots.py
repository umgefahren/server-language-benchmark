#! /usr/bin/env python
import json
import os
from datetime import timedelta

import matplotlib.pyplot as plt

def read_file(path):
    with open(path) as f:
        return [json.loads(l) for l in f.readlines()]

def save_svg(name):
    if not os.path.exists("report"):
        os.mkdir("report")

    plt.savefig(f"report/{name}.svg")

def convert_to_delta(value):
    secs = value["secs"]
    nanos = value["nanos"]
    micros = nanos / 1000
    delta = timedelta(seconds=secs, microseconds=micros)

    return delta.total_seconds()

def analyze_file(path):
    records = read_file(path)
 
    def accumulate_deltas(rec):
        return [convert_to_delta(r[rec]) for r in records]

    fields = ["start", "total", "set", "get0", "get1", "get2", "del"]

    ret = [accumulate_deltas(f) for f in fields]

    start_total = max(ret[0])
    ret[0] = [(start / start_total) * len(ret[0]) for start in ret[0]]

    return ret

def calc_mean_total(record):
    total_secods_over_all = 0
    for total in record[1]:
        total_secods_over_all += total

    return total_secods_over_all / len(record[1])

def plot_responsetime_all(results):
    _, ax = plt.subplots()
    for (l, r) in results:
        ax.scatter(r[0], r[1], marker=",", s=2, label=l)

    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])

    ax.set_xlabel("Request number (nth request)")
    ax.set_ylabel("Response time (seconds)")
    ax.legend(loc="center left", bbox_to_anchor=(1, 0.5))
    plt.yscale("log")

    save_svg("response_time")
    plt.show()

def plot_avg_responsetime_all(results):
    _, ax = plt.subplots()

    for (l, r) in results:
        ax.bar(l, calc_mean_total(r))

    ax.set_ylabel("Average response time (seconds)")
    ax.set_xlabel("Language")

    plt.yscale("log")
    plt.title("Average response time by language")
    save_svg("average_response_time")
    plt.show()

def plot_responsetime_each(results):
    labels = ["SET", "GET 0", "GET 1", "GET 2", "DEL"]
    for (l, r) in results:
        _, ax = plt.subplots()

        for i in range(5):
            ax.scatter(r[0], r[i+2], marker=",", s=2, label=labels[i])

        ax.set_ylabel("Response time (seconds)")
        ax.set_xlabel("Request number (nth request)")

        plt.yscale("log")
        plt.legend()
        plt.title(f"Response by step ({l})")
        save_svg(f"response_by_step_{l.lower()}")
        plt.show()

def main():
    try:
        files = [f for f in os.listdir("results") if f.endswith(".txt")]
    except:
        print("No results directory, please run the benchmarks first.")
        return

    results = [(l.split(".")[0], analyze_file("results/" + l)) for l in files]
    plot_responsetime_all(results)
    plot_avg_responsetime_all(results)
    plot_responsetime_each(results)

if __name__ == "__main__":
    main()
