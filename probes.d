/*
 *  probes.d
 *  FemtoHTTP
 *
 *  Created by Ben Vanik on 10/14/08.
 *  Copyright 2008 Ben Vanik ( http://www.noxa.org ). All rights reserved.
 *
 */

provider femtohttp {

    /* new host added to the pool */
    probe hostpool__added(char* /*name*/, int /*port*/);
    
    /* new connection created */
    probe host__new__connection(int /*id*/, char* /*name*/, int /*port*/);
    /* obtained a connection */
    probe host__obtain__connection(int /*id*/, char* /*name*/, int /*port*/, int /*isReused*/);
    /* killed a dead idle connection */
    probe host__killed__idle(int /*id*/, char* /*name*/, int /*port*/);
    /* closed a connection - wasDead flag denotes whether it was closed because it failed or because it was no longer needed */
    probe host__close__connection(int /*id*/, char* /*name*/, int /*port*/, int /*allowReuse*/, int /*wasDead*/);
    /* failed to open a new connection */
    probe host__new__failed(int /*id*/, char* /*name*/, int /*port*/);
    /* had to wait for a host to become free */
    probe host__pre__wait__for__socket(char* /*name*/, int /*port*/);
    probe host__wait__for__socket(char* /*name*/, int /*port*/);
    
    /* look up a host name */
    probe socket__pre__hostname__lookup(char* /*name*/);
    probe socket__hostname__lookup(char* /*name*/);
    /* a host name lookup failed */
    probe socket__hostname__lookup__failed(char* /*name*/, int /*error*/);
    
    /* opened/connected a socket */
    probe socket__pre__open(int /*id*/, char* /*name*/, int /*port*/);
    probe socket__open(int /*id*/, char* /*name*/, int /*port*/);
    /* socket closed */
    probe socket__close(int /*id*/, char* /*name*/, int /*port*/);
    
    /* queried socket status */
    probe socket__pre__querystatus(int /*id*/, char* /*name*/, int /*port*/);
    probe socket__querystatus(int /*id*/, char* /*name*/, int /*port*/);
    /* waited until data present */
    probe socket__pre__waituntildatapresent(int /*id*/, char* /*name*/, int /*port*/);
    probe socket__waituntildatapresent(int /*id*/, char* /*name*/, int /*port*/);
    
    /* read a chunk of data */
    probe socket__pre__readchunk(int /*id*/, char* /*name*/, int /*port*/);
    probe socket__readchunk(int /*id*/, char* /*name*/, int /*port*/, int /*lengthRead*/);
    /* write a chunk of data */
    probe socket__pre__writechunk(int /*id*/, char* /*name*/, int /*port*/, int /*length*/);
    probe socket__writechunk(int /*id*/, char* /*name*/, int /*port*/, int /*lengthWritten*/);
    
    /* socket errors */
    probe socket__open__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    probe socket__connect__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    probe socket__querystatus__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    probe socket__waituntildatapresent__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    probe socket__readchunk__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    probe socket__writechunk__failed(int /*id*/, char* /*name*/, int /*port*/, int /*error*/);
    
    /* NOTE: assume all http- as being only usable on a single thread, so it's safe to store the url from
     * http-begin in thread state and pull it on subsequent calls */
    /* wraps http begin/end*/
    probe http__begin(char* /*url*/);
    probe http__end();
    /* http transaction obtained the given socket */
    probe http__using__socket(int /*id*/);
    
    /* needed to retry a socket (was idle and dead, so need to get another) */
    probe http__socket__retry();
    /* needed to retry a socket (was new, but read after write failed) */
    probe http__socket__aggressive__retry();
    
    /* wrote header */
    probe http__pre__header__write(int /*length*/);
    probe http__header__write(int /*length*/);
    probe http__header__write__data(char* /*headerData*/);
    /* wrote request content */
    probe http__pre__content__write(int /*length*/);
    probe http__content__write(int /*length*/);
    probe http__content__write__data(char* /*data as string*/);
    /* read header */
    probe http__pre__header__read();
    probe http__header__read(int /*~length (off by a few bytes)*/);
    probe http__header__read__data(char* /*headerData*/);
    probe http__header__status__code(int /*statusCode*/, char* /*statusReason*/);
    /* content read - flag denotes whether it is a single read or a chunked read */
    probe http__pre__content__read(int /*isChunked*/);
    probe http__content__read(int /*length*/);
    probe http__content__read__data(char* /*data*/);
    probe http__pre__content__chunk();
    probe http__content__chunk(int /*chunkLength*/);
    
    /* got a redirect */
    probe http__redirect(int /*statusCode*/, char* /*targetUrl*/);
    
    /* response will automatically decompress content */
    probe response__auto__decompress();
    /* decompressed content from the server */
    probe response__pre__decompress();
    probe response__decompress(int /*preLength*/, int /*postLength*/, int /*succeeded*/);

};
