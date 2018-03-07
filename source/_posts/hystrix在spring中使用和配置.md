---
title: hystrix在spring中使用和配置
date: 2018-02-05 15:44:35
tags: [微服务, microservice]
---
# hystrix在spring中使用和配置 - 微服务

>     这篇文章是整理的一些Hystrix的经验。

## Hystrix启用

在应用主类中使用 @EnableCircuitBreaker 或 @EnableHystrix 注解开启Hystrix的使用。

## Hystrix依赖隔离

* Hystrix使用命令模式HystrixCommand(Command)包装依赖调用逻辑，每个命令在单独线程中/信号授权下执行。
* 可配置依赖调用超时时间,超时时间一般设为比99.5%平均时间略高即可.当调用超时时，直接返回或执行fallback逻辑。
* 为每个依赖提供一个小的线程池（或信号），如果线程池已满调用将被立即拒绝，默认不采用排队.加速失败判定时间。
* 依赖调用结果分:成功，失败（抛出异常），超时，线程拒绝，短路。 请求失败(异常，拒绝，超时，短路)时执行fallback(降级)逻辑。
* 提供熔断器组件,可以自动运行或手动调用,停止当前依赖一段时间(10秒)，熔断器默认错误率阈值为50%,超过将自动运行。

## Hystrix流程
![hystrix command flow chart](hystrix-command-flow-chart.png)

流程说明：

* 1:每次调用创建一个新的HystrixCommand,把依赖调用封装在run()方法中。
* 2:执行execute()/queue做同步或异步调用。
* 3:判断熔断器(circuit-breaker)是否打开,如果打开跳到步骤8,进行降级策略,如果关闭进入步骤。
* 4:判断线程池/队列/信号量是否跑满，如果跑满进入降级步骤8,否则继续后续步骤。
* 5:调用HystrixCommand的run方法.运行依赖逻辑。
* 5a:依赖逻辑调用超时,进入步骤8。
* 6:判断逻辑是否调用成功。
* 6a:返回成功调用结果。
* 6b:调用出错，进入步骤8。
* 7:计算熔断器状态,所有的运行状态(成功, 失败, 拒绝,超时)上报给熔断器，用于统计从而判断熔断器状态。
* 8:getFallback()降级逻辑.以下四种情况将触发getFallback调用：
  * (1):run()方法抛出非HystrixBadRequestException异常
  * (2):run()方法调用超时
  * (3):熔断器开启拦截调用
  * (4):线程池/队列/信号量是否跑满
* 8a:没有实现getFallback的Command将直接抛出异常。
* 8b:fallback降级逻辑调用成功直接返回。
* 8c:降级逻辑调用失败抛出异常。
* 9:返回执行成功结果。

## Hystrix服务降级

在为具体执行逻辑的函数上增加 @HystrixCommand 注解来指定服务降级方法,例如:

```JAVA
@HystrixCommand(fallbackMethod = "fallback")
public String consumer() {
    return restTemplate.getForObject("http://eureka-client/dc", String.class);
}

public String fallback() {
    return "fallback";
}
```

当consumer出现异常的时候，服务请求会通过HystrixCommand注解中指定的降级逻辑进行执行，因此该请求的结果返回了fallback。

## Hystrix隔离

Hystrix隔离方式采用线程/信号的方式,通过隔离限制依赖的并发量和阻塞扩散。
其实，我们在定义服务降级的时候，已经自动的实现了依赖隔离。

## Hystrix熔断器 Circuit Breaker

每个熔断器默认维护10个bucket,每秒一个bucket,每个bucket记录成功,失败,超时,拒绝的状态，默认错误超过50%且10秒内超过20个请求进行中断拦截.

## 例1：
```JAVA
@HystrixCommand(groupKey = "productStockOpLog", commandKey = "addProductStockOpLog", fallbackMethod = "addProductStockOpLogFallback",
    commandProperties = {
        @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "400"),//指定多久超时，单位毫秒。超时进fallback
        @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold", value = "10"),//判断熔断的最少请求数，默认是10；只有在一个统计窗口内处理的请求数量达到这个阈值，才会进行熔断与否的判断
        @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage", value = "10"),//判断熔断的阈值，默认值50，表示在一个统计窗口内有50%的请求处理失败，会触发熔断
    }
)
public void addProductStockOpLog(Long sku_id, Object old_value, Object new_value) throws Exception {
    if (new_value != null && !new_value.equals(old_value)) {
        doAddOpLog(null, null, sku_id, null, ProductOpType.PRODUCT_STOCK, old_value != null ? String.valueOf(old_value) : null, String.valueOf(new_value), 0, "C端", null);
    }
}

public void addProductStockOpLogFallback(Long sku_id, Object old_value, Object new_value) throws Exception {
    LOGGER.warn("发送商品库存变更消息失败,进入Fallback,skuId:{},oldValue:{},newValue:{}", sku_id, old_value, new_value);
}
```

## 例2：

```JAVA
@HystrixCommand(groupKey="UserGroup", commandKey = "GetUserByIdCommand"，
commandProperties = {
    @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "100"),//指定多久超时，单位毫秒。超时进fallback
    @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold", value = "10"),//判断熔断的最少请求数，默认是10；只有在一个统计窗口内处理的请求数量达到这个阈值，才会进行熔断与否的判断
    @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage", value = "10"),//判断熔断的阈值，默认值50，表示在一个统计窗口内有50%的请求处理失败，会触发熔断
},
threadPoolProperties = {
        @HystrixProperty(name = "coreSize", value = "30"),
        @HystrixProperty(name = "maxQueueSize", value = "101"),
        @HystrixProperty(name = "keepAliveTimeMinutes", value = "2"),
        @HystrixProperty(name = "queueSizeRejectionThreshold", value = "15"),
        @HystrixProperty(name = "metrics.rollingStats.numBuckets", value = "12"),
        @HystrixProperty(name = "metrics.rollingStats.timeInMilliseconds", value = "1440")
})
```

说明：

* hystrix函数必须为public，fallback函数可以为private。两者需要返回值和参数相同。
* 参数配置：

|参数说明       |值         |备注   |
|:-             |:-         |:-     |
|groupKey|productStockOpLog|group标识，一个group使用一个线程池|
|commandKey|addProductStockOpLog|command标识|
|fallbackMethod|addProductStockOpLogFallback|fallback方法，两者需要返回值和参数相同|
|超时时间设置|400ms|执行策略，在THREAD模式下，达到超时时间，可以中断 For most circuits, you should try to set their timeout values close to the 99.5th percentile of a normal healthy system so they will cut off bad requests and not let them take up system resources or affect user behavi|
|统计窗口（10s）内最少请求数|10|熔断策略|
|熔断多少秒后去尝试请求|5s|熔断策略，默认值|
|熔断阀值|10%|熔断策略：一个统计窗口内有10%的请求处理失败，会触发熔断|
|线程池coreSize|10|默认值（推荐值）|
|线程池maxQueueSize|-1|即线程池队列为SynchronousQueue|

## 配置参数说明

|分类         |参数         |作用     |     默认值|     备注|
|:-           |:-           |:-       |:-         |:-       |
|基本参数|groupKey|表示所属的group，一个group共用线程池|getClass().getSimpleName();||
|基本参数|commandKey||当前执行方法名||
|Execution （ 控制HystrixCommand.run()的执行策略）|execution.isolation.strategy|隔离策略，有THREAD和SEMAPHORE THREAD|当前执行方法名||
|Execution|execution.isolation.thread.timeoutInMilliseconds|超时时间|1000ms|默认值：1000 在THREAD模式下，达到超时时间，可以中断 在SEMAPHORE模式下，会等待执行完成后，再去判断是否超时 设置标准： 有retry，99meantime+avg meantime 没有retry，99.5meantime|
|Execution|execution.timeout.enabled|是否打开超时|true||
|Execution|execution.isolation.thread.interruptOnTimeout|是否打开超时线程中断|true|THREAD模式有效|
|Execution|execution.isolation.semaphore.maxConcurrentRequests|信号量最大并发度|10|SEMAPHORE模式有效|
|Fallback （ 设置当fallback降级发生时的策略）|fallback.isolation.semaphore.maxConcurrentRequests|fallback最大并发度|10||
|Fallback|fallback.enabled|fallback是否可用|true||
|Circuit Breaker （配置熔断的策略）|circuitBreaker.enabled|是否开启熔断|true||
|Circuit Breaker|circuitBreaker.requestVolumeThreshold|一个统计窗口内熔断触发的最小个数/10s|20||
|Circuit Breaker|circuitBreaker.sleepWindowInMilliseconds|熔断多少秒后去尝试请求|5000ms||
|Circuit Breaker|circuitBreaker.errorThresholdPercentage|失败率达到多少百分比后熔断|50|主要根据依赖重要性进行调整|
|Circuit Breaker|circuitBreaker.forceOpen|是否强制开启熔断|||
|Circuit Breaker|circuitBreaker.forceClosed|是否强制关闭熔断||如果是强依赖，应该设置为true|
|Metrics （设置关于HystrixCommand执行需要的统计信息）|metrics.rollingStats.timeInMilliseconds|设置统计滚动窗口的长度，以毫秒为单位。用于监控和熔断器|10000|滚动窗口被分隔成桶(bucket)，并且进行滚动。 例如这个属性设置10s(10000)，一个桶是1s|
|Metrics|metrics.rollingStats.numBuckets|设置统计窗口的桶数量|10|metrics.rollingStats.timeInMilliseconds必须能被这个值整除|
|Metrics|metrics.rollingPercentile.enabled|设置执行时间是否被跟踪，并且计算各个百分比，50%,90%等的时间|true||
|Metrics|metrics.rollingPercentile.timeInMilliseconds|设置执行时间在滚动窗口中保留时间，用来计算百分比|60000ms||
|Metrics|metrics.rollingPercentile.numBuckets|设置rollingPercentile窗口的桶数量|6|metrics.rollingPercentile.timeInMilliseconds必须能被这个值整除|
|Metrics|metrics.rollingPercentile.bucketSize|metrics.rollingPercentile.bucketSize|100|如果设置为100，但是有500次求情，则只会计算最近的100次|
|Metrics|metrics.healthSnapshot.intervalInMilliseconds|采样时间间隔|500||
|Request Context ( 设置HystrixCommand使用的HystrixRequestContext相关的属性)|requestCache.enabled|设置是否缓存请求，request-scope内缓存|true||
|Request Context|requestLog.enabled|设置HystrixCommand执行和事件是否打印到HystrixRequestLog中|||
|ThreadPool Properties(配置HystrixCommand使用的线程池的属性)|coreSize|设置线程池的core size,这是最大的并发执行数量|10|设置标准：coreSize = requests per second at peak when healthy × 99th percentile latency in seconds + some breathing room 大多数情况下默认的10个线程都是值得建议的|
|ThreadPool Properties|maxQueueSize|最大队列长度。设置BlockingQueue的最大长度|-1|默认值：-1 如果使用正数，队列将从SynchronousQueue改为LinkedBlockingQueue|
|ThreadPool Properties|queueSizeRejectionThreshold|设置拒绝请求的临界值|5|此属性不适用于maxQueueSize = - 1时 设置设个值的原因是maxQueueSize值运行时不能改变，我们可以通过修改这个变量动态修改允许排队的长度|
|ThreadPool Properties|keepAliveTimeMinutes|设置keep-live时间|1分钟|这个一般用不到因为默认corePoolSize和maxPoolSize是一样的|

### Hystrix官方文档

<https://github.com/Netflix/Hystrix/wiki>

