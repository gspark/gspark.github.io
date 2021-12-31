---
title: RestTemplate重试
date: 2021-11-23 11:07:50
tags: spring
---

springframework 提供了 RestTemplate 作为 web 客户端，它提供了多种便捷访问远程 Http 服务的方法,能够大大提高客户端的编写效率。
RestTemplate 默认依赖 JDK 的 HTTP 连接工具，也可以通过 setRequestFactory 属性切换到不同的 HTTP 源，比如
Apache HttpComponents、Netty 和OkHttp。

使用 RestTemplate 调用服务的时候，因为网络波动造成的对方服务异常或者对方服务降级后又好了，我们可能会写个循环对
RestTemplate 的调用进行重试，但这样实现起来麻烦，代码也可能变得冗长。其实 RestTemplate 为我们提供了重试机制。

## HttpRequestRetryHandler

Apache 的 httpclient 的 HttpRequestRetryHandler 接口为我们提供了一种重试机制。大致代码如下：

```Java
    HttpClientBuilder clientBuilder = HttpClients.custom();
    HttpRequestRetryHandler retryHandler = new DefaultHttpRequestRetryHandler(retryTimes, false);
        clientBuilder.setDefaultRequestConfig(config).setRetryHandler(retryHandler)
```

这里采用的是 DefaultHttpRequestRetryHandler 实现了 HttpRequestRetryHandler 接口。

## ServiceUnavailableRetryStrategy

Apache 的 httpclient 的 ServiceUnavailableRetryStrategy 接口为我们提供了另外一种重试机制。大致代码如下：

```Java
    ServiceUnavailableRetryStrategy retryStrategy = new ServiceUnavailableRetryStrategy() {
        @Override
        public boolean retryRequest(HttpResponse response, int executionCount, HttpContext httpContext) {
            int statusCode = response.getStatusLine().getStatusCode();
            return executionCount < retryTimes && statusCode == HttpStatus.SC_SERVICE_UNAVAILABLE;
        }

        @Override
        public long getRetryInterval() {
            return retryInterval;
        }
    };

    clientBuilder.setDefaultRequestConfig(config).setRetryHandler(retryHandler)
            .setServiceUnavailableRetryStrategy(retryStrategy);
```

从上面的代码可以看出，HttpRequestRetryHandler 和 ServiceUnavailableRetryStrategy 这两种机制可以合起来使用。

## 区别

这两种重试机制的区别是什么呢？从名字来看，HttpRequestRetryHandler 是请求时重试，ServiceUnavailableRetryStrategy
是针对服务端的响应状态的重试。实现上也是如此：
DefaultHttpRequestRetryHandler 主要实现的是请求的异常进行重试：

* InterruptedIOException
* UnknownHostException
* ConnectException
* SSLException

ServiceUnavailableRetryStrategy 的实现是请求成功了，但是 http 状态码可能不是 2xx，这种情况下的重试机制。如上例就是服务器返回
SC_SERVICE_UNAVAILABLE （503） 重试。

通过上面的了解，我们采用 RestTemplate 作为 http 的客户端，在实现重试时，就不用在每次调用的地方写循环来进行重试了。封装一个
创建 RestTemplate 的工具类，组合上面两个接口，就可以方便灵活的实现重试了。
