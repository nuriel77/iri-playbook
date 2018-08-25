.. _docker:

######
Docker 
######

The new release of IRI-playbook introduces a valuable feature where all services are run inside of Docker containers.

.. note::

  Docker is a tool designed to make it easier to create, deploy, and run applications by using containers. Containers allow a developer to package up an application with all of the parts it needs, such as libraries and other dependencies, and ship it all out as one package. By doing so, thanks to the container, the developer can rest assured that the application will run on any other Linux machine regardless of any customized settings that machine might have that could differ from the machine used for writing and testing the code.

`Source <https://opensource.com/resources/what-docker>`_

Docker Installation
===================

During the installation phase of the playbook, you are provided a selection menu where some options can be selected. One of those options is whether to install Docker on your server (enabled by default). Docker is the service which controls and managed containers on your server.

Services Management
===================

All the services installed by the playbook are "containerized" and controlled by Docker. Systemd (systemctl ...) drop-in files have been configured allowing control of the services as any other service running on the host (e.g. ``systemctl status iri`` or ``journalctl -u iri -e``).

Docker Network
==============

During the installation, the playbook has created a Docker network on the server to be used by IRI and peripheral services. This abstracts the service's networking from the host's network and only required ports are exposed on the host (or publicly where needed).

Service's Configurations and Data Directories
=============================================

Services' configuration files are normally located on paths on the host itself and mounted "read-only" to the appropriate container.

Data directories such as IRI's database are mounted from the host into the container as "read-write".

Even if the container gets permanently removed, the data directory remains on the host.

Docker Images
=============

In order for docker to run services in containers it requires an image per container. For example, IOTA provides an official IRI Docker image which gets automatically updated when a new version of IRI is released.

When you upgrade IRI (using ``iric`` for example) the new image/version is downloaded to your server, IRI restarted and that's about it.

You can easily rollback to the older version.

Docker images are shipped in the format: ``image-name:tag``, where by default, if no tag is specified, ``latest`` is the default.

It is important to maintain a tag/version to help identify the version of software of each container's image. Unfortunately, in somecases, that was not possilbe due to upstream image not maintaining versioned tags.

## TODO: Provide some commands to help manage docker images and containers, cleanup old images etc.
