# Disc Based Functionality in Docker

When running Docker containers, any data that is written to disc is owned by the container and hence once the containers is removed the data is gone. This can be an issue for data that needs to persist beyond the life of a container or data that must be portable between Docker hosts so that the same container can be started on different hosts. To solve this, Docker provides a lot of functionality that it terms Volumes. Volumes allows disc data to be mapped in from the container to another location, such as the Docker host or another container. 

Besides the obvious logging functionality, Oracle Coherence has two other main pieces of functionality that rely on disc access.  

## Elastic Data
When using Elastic Data in Coherence, the cache data is written to disc but this data is transient in nature; when the storage member shuts down, the data is no longer of use. This means that configuring elastic data to use the container's internal storage should not be a problem. If the container shuts down. then so has the storage member so the data would have been lost anyway. 

Using volumes external to the container may be useful if elastic data is to be mapped to SSDs that are mounted on the Docker host. In this case, Docker's Volume functionality can be used to mount the SSDs at a fixed location in the container and the storage member can configured elastic data to the same location.

## Persistence
When using Coherence Persistence functionality, then this data is designed to live for longer than the storage member and can be used to recover a crashed storage member on restart. Therefore, when running in Docker, it is advisable to also use Docker's Volume functionality to map a mount point in the container to an external storage location on the Docker host. If a container is shut down or dies, then on restart the persisted data is still available. There are also third-party Volume plugins available for Docker that make Volumes portable between Docker hosts so a container that died on one host can be restarted on another host without loss of its data volumes.   