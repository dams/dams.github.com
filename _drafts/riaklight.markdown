---
layout: post
title: "Riak::Light, and other Riak Perl clients"
---

# {{ page.title }}

<!-- ![New and Improved!](/images/val_approuve.png "I borrowed the image from @yenzie - -->
<!--  hope you don't mind, Yannick !") -->

## Disclaimer ##

I am not a Riak pro, especially on the administration side. I have used it a
lot, but if you see any error, misconception or missing information, please let
me know in the comments.

## Riak ##

[Riak](http://basho.com/riak/) is an open source **key value** distributed
database. It consists of a so-called Ring of VNodes, which run on one or more
servers, storing data in a redundant manner, making it **scalable**, **fast**,
**secure**, **fault-tolerant**.

## Features ##

Riak provides a limited numbers of features, but they are carefully chosen, and
properly implemented.

### key / value ###

It's the main feature: set/get a value. Nothing fancy here, except that it
handles minimal replication of the data, quorum decision between underlying
nodes, and provides a way to resolve conflicts (to avoid race conditions).

### multiple backends ###

Riak can be used with Bitcask, or LevelDB. There is also the memory backend

* Bitcask basically is a simple backend, storing all the keys in memory, and
  values on disk and memory cache. It has a slightly better performance
  (actually, a more steady performance) than LevelDB, but requires a minimum
  amount of memory (to store keys for the given node), and doesn't implement
  secondary indexes. However, it implements automatic expiration

* LevelDB maintains a sorted list of keys, and keys plus values are stored on
  disk, and relies on the OS for caching (I think). It can then implement
  secondary indexes, but not automatic expiration.

* The memory backend: I've never used it, so I won't talk about it. It's rarely
  used in production. Redis is usually a better option, and dramatically
  faster.

### buckets (namespace) ###

Each key belongs to a bucket, some kind of namespace. Keys must be unique
inside a bucket, so you can have the same key name in different buckets

### links ###

I've not used this feature, but an object can point to an other one, by reading
its properties. So you can do link walking, which is quite handy for graphs and
related concepts.

### Accessing a key ###

To be able to access a key, you have to know its name. You can technically list
all the keys, but don't do that on production, it's slow. The key name can be
considered as *first index* to retrieve the value.

You can use the *REST API* to connect to Riak, but I tend to prefer the
*Protocol Buffers API* connection, as it's faster.

### secondary indexes ###

Available with the elevelDB backend, *secondary indexes* are additional
properties that can be added to objects, so that they can be retrieved via
other means than just their key names.

### Map Reduce ###

As numerous NoSQL databases, Riak supports Map Reduce operations

## Net::Riak ##

For some time, Net::Riak was the only Perl client. It's powerful and full
featured, but its code is quite complex (some might say overengineered), and
uses Moose extensively. Specifically, every value retrieved from Riak is an
object. This and other stuff makes it quite slow (from a client CPU usage point
of view). And sometimes it maters, when you want to process very quickly a lot
of keys, and have a very fast Riak server nearby.

## Riak::Light ##

