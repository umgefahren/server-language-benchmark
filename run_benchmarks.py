#! /usr/bin/env python
import docker
import os
import sys

IGNORE = ["client"]

def log(msg):
    print(f"[run benchmarks] {msg}")


def get_langs():
    os.chdir(sys.path[0])
    return [
        (lang, [
            fname
            for fname in os.listdir(lang)
            if fname.startswith("Dockerfile")
        ])
        for lang in os.listdir(".")
        if os.path.isdir(lang)
        if lang not in IGNORE
        if any("Dockerfile" in fname for fname in os.listdir(lang))
        if ".broken" not in os.listdir(lang)
    ]


def run_benchmark(d, lang, modes=["Dockerfile"]):
    for mode in modes:
        os.chdir(os.path.join(sys.path[0], lang))

        mode_name = mode[len("Dockerfile"):]
        bench_name = f"{lang}{mode_name}".lower()

        log(f"Building docker image for benchmark {bench_name}")
        image_name = f"server-benchmark-{lang.lower()}"
        d.images.build(path=".", dockerfile=mode, tag=image_name)

        log("Starting server application")
        container = d.containers.run(
                image_name,
                auto_remove=True,
                detach=True,
                ports={8080: 8080}
            )

        log(f"Running benchmark {bench_name}")
        os.chdir(os.path.join(sys.path[0], "client"))
        exit_code = os.system("target/release/client benchmark")
        if exit_code != 0:
            log(f"Benchmark {bench_name} failed with exit code {exit_code}")
        else:
            log("Benchmark finished")
            os.chdir(sys.path[0])
            os.rename("client/bench.txt", f"results/{bench_name}.txt")

        container.stop(timeout=1)


def setup_client():
    os.chdir(os.path.join(sys.path[0], "client"))

    log("Compiling benchmark client")
    os.system("cargo build --release") # TODO: use docker
 
    log("Generating test data")
    os.system("target/release/client generate")


def main():
    os.chdir(sys.path[0])
    if not os.path.exists("results"):
        os.mkdir("results")

    d = docker.from_env()

    if len(sys.argv) >= 2:
        if (sys.argv[1] == "help"):
            print("""Usage:    ./run_benchmarks.py [<language> [mode]]
Examples: ./run_benchmarks.py Ruby yjit
          ./run_benchmarks.py Java
          ./run_benchmarks.py""")
            return
        lang = sys.argv[1]

        setup_client()
        if len(sys.argv) >= 3:
            mode = sys.argv[2]
            log(f"Benchmarking {lang} {mode}")
            run_benchmark(d, lang, [f"Dockerfile-{mode}"])
        else:
            log(f"Benchmarking {lang}")
            run_benchmark(d, lang, [f"Dockerfile"])
    else:
        langs = get_langs()
        setup_client()
        for (lang, modes) in langs:
            log(f"Beginning benchmarking {lang}")
            run_benchmark(d, lang, modes)

        log("All benchmarks have finished")


if __name__ == "__main__":
    main()
