# `odc_box`

This repository hosts all you need to install an *Open Data Cube* instance as a docker container that serves a Jupyter notebook environment running a Python kernel and an R kernel. It is based on the [Cube-in-a-box](https://github.com/opendatacube/cube-in-a-box) project. 

## Additional features

* an R kernel and its upstream dependencies, initialized to connect with the Jupyter environment,
* a pre-installed suite of R packages for spatial analysis as well as there system requirements
* helper scripts for quick starting, stopping and re-deploying of the container environment (see below),
* a revised `README.md` with installation instructions

See the commit history for all changes to the original repository.

## Installation

Make sure to have [`docker`](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) and [`docker-compose`](https://docs.docker.com/compose/install/#install-compose-on-linux-systems) installed on your host system. Depending on your host system and your `docker`/`docker_compose` installation, you might need `sudo` rights for the following steps.

Clone this repository to a directory of your choice, e.g. using

```
git clone https://github.com/16EAGLE/odc_box/
```

and `cd` into its main directory. To start the container (and build it the first time), run:

```
./docker_start
```

To initialize the jupyter environment and pull Sentinel-2A example data, open a new shell and run:

```
./docker_init
```

Wait for its completion. You may then now access your local Jupyter environment in a browser on your host machine under [http://localhost](http://localhost). Use the password `secretpassword` to authenticate.

See the notebook `Sentinel_2.ipynb` for examples. Note that you can index additional areas using the `Indexing_More_Data.ipynb` notebook.

To stop the container, from a shell other then the one the docker container is running in, run:

```
./docker_stop
```

To fully clean your docker environment from images pulled for `odc_box` and to allow a fresh re-deploy, run

```
./docker_clean
```

before starting over. Note that with each re-deploy, a new docker volume is created containing your indexed data. You may want to prune your docker volumes from time to time, e.g. using `docker volume rm $(docker volume ls -q -f 'dangling=true')`. Note that this will remove **all** docker volumes, also those from other docker instances that might be running on your host system.


## Troubleshooting

**Occupied TCP port**

Error message:

```
./docker_start
#> ERROR: for postgres  Cannot start service postgres: driver failed programming external connectivity on endpoint odc_box_postgres_1 (...): Error starting userland proxy: listen tcp4 0.0.0.0:5432: bind: address already in use
```

Reason: The default `postgres` port `5432` seems to be used by some service (maybe `postgres`?) running on your host system.

Solution: Check whether this is true by running `lsof -i :5432`. You may want to kill the processes that are displayed using their associated PIDs with `kill <PID>`.


