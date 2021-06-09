# `odc_box`

This repository hosts all you need to install an *Open Data Cube* instance as a docker container that serves a Jupyter notebook environment running a Python kernel and an R kernel. It is based on the [Cube-in-a-box](https://github.com/opendatacube/cube-in-a-box) project. The changes and additions include (i) a revised `Dockerfile`, adding instructions to install R, its upstream dependencies and connect it with the Jupyter environment, (ii) helper scripts for quick re-deploys of the container environment, (iii) a revised `README.md` and (iv) additional Python dependencies. See the commit history for all changes to the original repository.

## Installation

Make sure to have [`docker`](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) and [`docker-compose`](https://docs.docker.com/compose/install/#install-compose-on-linux-systems) installed on your host system.

Clone this repository to a directory of your choice, e.g. using

```
git clone https://github.com/16EAGLE/odc_box/
```

and `cd` into its main directory. To start the container (and build it the first time), run:

```
sudo ./docker_start
```

To initialize the jupyter environment and pull Sentinel-2A example data, in another shell run the following command and wait for its completion:

```
sudo ./docker_init
```

You may now access your local Jupyter environment in a browser on your host machine under [http://localhost](http://localhost). Use the password `secretpassword` to authenticate.

see the notebook `Sentinel_2.ipynb` for examples. Note that you can index additional areas using the `Indexing_More_Data.ipynb` notebook.

To stop the container, from a shell other then the one the docker container is running in, run:

```
sudo ./docker_stop
```

To fully clean your docker environemnt from containers, images and volumes created for `odc_box` and to allow a fresh re-deploy, run

```
sudo ./docker_clean
```

before starting over.


## Troubleshooting

**Occupied TCP port**

Error message:

```
sudo ./docker_start
#> ERROR: for postgres  Cannot start service postgres: driver failed programming external connectivity on endpoint odc_box_postgres_1 (...): Error starting userland proxy: listen tcp4 0.0.0.0:5432: bind: address already in use
```

Reason: The default `postgres` port `5432` seems to be used by some service (maybe `postgres`?) running on your host system.

Solution: Check whether this is true by running `sudo lsof -i :5432`. You may want to kill the processes that are displayed using their associated PIDs with `kill <PID>`.


