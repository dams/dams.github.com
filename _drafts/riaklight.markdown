---
layout: post
title: "Riak::Light"
---

# {{ page.title }}

![New and Improved!](/images/val_approuve.png "I borrowed the image from @yenzie -
 hope you don't mind, Yannick !")

## Riak

[Riak](http://basho.com/riak/) is an open source **key value** distributed
database. At $work, we use it extensively (storing currently 1 billion entries,
and counting). It is **scalable**, **fast**, **secure**, **fault-tolerant**.

## Features

Riak has a limited numbers of features, but they are carefully chosen, and properly implemented.

### key value

It's the main feature: set/get a value. Nothing fancy here, except that it
handles minimal replication of the data, quorum decision between underlying
nodes, and provides a way to resolve conflicts (to avoid race conditions).

### counters

New in the last versions, simple counters can be atomically manipulated.

###


### multiple backends

Riak can be used with Bitcask, or LevelDB. There is also the memory backend

* Bitcask basically is a simple backend, storing all the keys in memory, and
  values on disk and memory cache. It has a slightly better performance
  (actually, a more steady performance) than LevelDB, but requires a minimum
  amount of memory (to store keys for the given node), and doesn't implement
  secondary indexes. However, it implements automatic expiration

* LevelDB maintains a sorted list of keys, and keys plus values are stored on
  disk, and rely on the OS for caching (I think). It can then implement
  secondary indexes, but not automatic expiration.

* The memory backend I've never used, so I won't talk about it. It's rarely
  used in production. Redis is usually a better option, and dramatically
  faster.

buckets (namespace)


