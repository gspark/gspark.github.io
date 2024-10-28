---
title: aop实现日志入库@AfterThrowing调用正常，数据未提交
date: 2023-04-13 19:43:41
tags:
---

最近开发使用AOP方式实现系统审计日志，主要功能为**方法**开始、结束、异常时记录日志并存入数据库。测试时发现系统抛出异常时，@AfterThrowing 异常处理切入点可正常调用，但该切入点记录的数据未能正常提交数据库。查找原因，发现有两种：

1. Spring事务是通过AOP实现的，记录日志的AOP与事务AOP存在执行顺序问题，如果事务AOP先执行了，@AfterThrowing 中数据则无法提交。
2. @AfterThrowing 处理方法和抛出异常的**方法**在同一个事务中，@AfterThrowing 处理完成后，抛出异常的**方法**因为有异常，导致事务回滚，所以记录数据未能提交数据库。

## 解决方案

1. 解决办法为 @Aspect 切面类实现org.springframework.core.orderd接口或使用@Order注解,推荐使用注解方式。然后将 Order 的值设置得很小。值越小，优先级越高。
2. 第2种情况得解决，在AOP的逻辑中启用一个新的事务。
   测试发现，通过在 @AfterThrowing 方法上加上注解 @Transactional，并指定传播行为是**REQUIRES_NEW**依然不行。因为 @Transactional 也是声明式事务，本身就是AOP实现的，在AOP的代码中不起作用。就只能使用 spring 的编程式事务了，需要引入 TransactionTemplate。实现如下：

   ```Java
    @Autowired
    private TransactionTemplate transactionTemplate;

    @AfterThrowing(pointcut = "pointcut()", throwing = "e")
    public void doAfterThrowing(JoinPoint joinPoint, Throwable e) throws Throwable {
        //声明式事务在切面中不起作用，需使用编程式事务
        //设置传播行为：总是新启一个事务，如果存在原事务，就挂起原事务
        transactionTemplate.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        transactionTemplate.execute(TransactionCallback<T>() {
            @Override
            public T doInTransaction(TransactionStatus status) {
                // 数据库操作
            }
        });
    }
   ```

   值得注意的是，transactionTemplate 不一定可以注入，程序启动时可能会报：“No qualifying bean of type TransactionTemplate”这样的错误，那么就用 PlatformTransactionManager 构造一个transactionTemplate。

   ```Java
    @Autowired
    private PlatformTransactionManager transactionManager;

    ...
    transactionTemplate = new TransactionTemplate(transactionManager);
   ```
