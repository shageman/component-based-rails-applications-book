# Source Code to _Component-Based Rails Applications_ by Stephan Hagemann

This repository holds the source code used in my book on Component-based Rails Applications.

It is organized by chapter and section encoded as _cXs0Y_ for "Chapter X, Section Y." If a section adds no code that is 
specific to it, it may use the source code from the last section preceding it that does have source code samples attached.

Because the Ruby and Rails ecosystems are moving so rapidly, creating a book about high-level structural concepts is 
tough when underlying libraries constantly require subtle changes to the sample code. To this end, all source code 
was written against a local gem server, which only serves a very limited number of gems (and not their latest
versions). Please check out the development section of this readme to get more info on how this server is ue

## References

* [The Book at Pearson](https://www.pearson.com/us/higher-education/program/Hagemann-Component-Based-Rails-Applications-Large-Domains-Under-Control/PGM1797138.html) 
* [stephanhagemann.com](http://stephanhagemann.com) - The author's website
* [cbra.info](http://www.cbra.info) - A collection of resource on Component-based Rails 

## Development - Getting Started

The `docker` and `generator_scripts` folders are for development of the chapter samples. In fact, all of the samples 
were generated via script in a concourse pipeline. I.e., every transformation described in a chapter 
can be executed via the shell script belonging to that chapter.  

These instructions assume you have docker running on OSX.

### Starting Concourse and Minio and Geminabox on Docker
In one terminal execute this:

~~~~~~~~
cd docker

mkdir -p keys/web keys/worker

ssh-keygen -t rsa -f ./keys/web/tsa_host_key -N ''
ssh-keygen -t rsa -f ./keys/web/session_signing_key -N ''

ssh-keygen -t rsa -f ./keys/worker/worker_key -N ''

cp ./keys/worker/worker_key.pub ./keys/web/authorized_worker_keys
cp ./keys/web/tsa_host_key.pub ./keys/worker

docker-compose up
~~~~~~~~

This will start a [concourse]() (CI server), a [geminabox]() (gem server), and a [minio]() (S3 
compatible server) 

### Get the Pipeline Running
In a different terminal
~~~~~~~~
cd generator_scripts
fly -t local login

fly -t local set-pipeline -p cbra_full -c ci/cbra_full.yml
fly -t local unpause-pipeline -p cbra_full
~~~~~~~~

### Issues
When stuff goes wrong, repeat the above steps after doing this:

~~~~~~~~  
docker stop $(docker ps -aq)     # Stop all running containers
docker rm $(docker ps -a -q)     # Delete all containers
docker rmi $(docker images -q)   # Delete all images
~~~~~~~~ 

What goes wrong?

* geminabox looses gems... Give http://localhost:9292/reindex a try. Then, do the above
* concourse can't find `generator_scripts` anymore (errors with "no such file"). Definitely do the above
* nothing works reliably anymore. Reinstall docker.
 

