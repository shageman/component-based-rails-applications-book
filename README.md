# Source Code to _Component-Based Rails Applications_ by Stephan Hagemann

This repository holds the source code used in my book on Component-based Rails Applications.

It is organized by chapter and section encoded as _cXs0Y_ for "Chapter X, Section Y." If a section adds no code that is 
specific to it, it may use the source code from the last section preceding it that does have source code samples attached.

Because the Ruby and Rails ecosystems are moving so rapidly, creating a book about high-level structural concepts is 
tough when underlying libraries constantly require subtle changes to the sample code. To this end, all source code 
was written against a local gem server, which only serves a very limited number of gems (and not their latest
versions). 

Please check out the development section of this readme to get more info on how this server is used.

## Running/Testing/Executing Anything for the Sportsball App in a Particular Chapter

When trying to bundle the dependencies of any of the chapters, this will likely happen:

~~~~~~~  
$ bundle
Could not reach host geminabox. Check your network connection and try again.
~~~~~~~  

There are two ways to solve this, described next. 

### Change the App's Gemfiles
If you want to develop on top of the source code from a Chapter without installing docker or geminabox, simply point the all gemfiles at rubygems.

For this in every `Gemfile` (there is one per component: `find . -name 'Gemfile'`), the first line has to be changed:

~~~~~~~~  
# CURRENT
source "http://geminabox:9292"

#NEW
source "https://rubygems.org"
~~~~~~~~

Now you should be able to `bundle` successfully and check that everything is in order by running `./build.sh` (only available in C3S02 and after).

Depending on your OS and version of shell, there is probably a one liner do this: [ask stackexchange](https://unix.stackexchange.com/questions/112023/how-can-i-replace-a-string-in-a-files).

### Run the geminabox Gem Server
If you want to have everything be exactly as it is in the book, you might want to use the entire pipeline as it was set up for the book.
This is also true if you intend to make updates to the sourcecode of the book (e.g., to a new version of Rails).    

To run geminabox, start the docker containers as described in the [Concourse/Minio/Geminabox](#Starting-Concourse-and-Minio-and-Geminabox-on-Docker).

## References

* [Get the book!](https://www.amazon.com/Component-Based-Rails-Applications-Addison-Wesley-Professional/dp/0134774582) 
* [stephanhagemann.com](http://stephanhagemann.com) - the author's website
* [cbra.info](http://www.cbra.info) - a collection of resource on Component-based Rails 

## Development

The `docker` and `generator_scripts` folders are for development of the chapter samples. In fact, all of the samples 
were generated via script in a concourse pipeline. I.e., every transformation described in a chapter 
can be executed via the shell script belonging to that chapter.  

*These instructions assume that you have [docker](https://www.docker.com/) running on OSX.*

### Starting Concourse and Minio and Geminabox on Docker

[Concourse](https://github.com/concourse/concourse) acts as our CI server, which will run the pipeline.
[Geminabox](https://github.com/geminabox/geminabox) is our local gem server, preconfigured with all the needed gems.
[Minio](https://github.com/minio/minio) is our local S3 compatible serverm, which will hold the outputs of the pipeline.

In one terminal execute the following to install the needed docker containers.
~~~~~~~~
cd docker
docker-compose up
~~~~~~~~

The services should be running at these locations:

* Concourse: [http://localhost:8080/](http://localhost:8080/)
* Geminabox: [http://localhost:9292/](http://localhost:9292/)
* Minio: [http://localhost:9000/](http://localhost:9000/)

If any of the containers fail to start, please check the docs of the docker images used for updates to their respective config:

* [concourse docker](https://github.com/concourse/concourse-docker)
* [geminabox docker](https://github.com/yuri-karpovich/geminabox)
* [minio docker](https://github.com/minio/minio)

### Get the Pipeline Running

Concourse gets configured via its [fly CLI](https://concourse-ci.org/fly.html). Download it [here](https://concourse-ci.org/download.html). Or on Mac with brew installed via `brew cask install fly`.

To point fly at the locally running instance of concourse, first do this (and follow the instructions on screen). The above concourse installation gave you a user `test` with password `test`.
~~~~~~~~
fly --target local login --team-name main --concourse-url http://localhost:8080
~~~~~~~~

Then, to configure and start the pipeline
~~~~~~~~
cd generator_scripts

fly -t local set-pipeline -p cbra_full -c ci/cbra_full.yml
fly -t local unpause-pipeline -p cbra_full
fly -t local trigger-job -j cbra_full/c2s01
~~~~~~~~

Now, navigating to [http://localhost:8080/teams/main/pipelines/cbra_full](http://localhost:8080/teams/main/pipelines/cbra_full) will show the running pipeline.

The output of the pipeline is *all* of the versions of the Sportsball codebase discussed in the book. Specifically, the output is a series of zip files in `./docker/minio/data/releases` - one zip file for each chapter / step of the pipeline.

### Issues

If your pipelines don't work after a docker shutdown, try `fly prune-worker`.

If things are still broken, repeat the above steps after doing this (*careful*: this will wipe out all of the docker images and their disks running on your machine):
~~~~~~~~  
docker stop $(docker ps -aq)     # Stop all running containers
docker rm $(docker ps -a -q)     # Delete all containers
docker rmi $(docker images -q)   # Delete all images
~~~~~~~~ 

What goes wrong?

* geminabox looses gems... Give [http://localhost:9292/reindex](http://localhost:9292/reindex) a try. Then, do the above
* concourse can't find `generator_scripts` anymore (errors with "no such file"). Definitely do the above
* nothing works reliably anymore. Reinstall docker.
