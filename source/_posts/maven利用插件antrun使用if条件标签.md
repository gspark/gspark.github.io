---
title: maven利用插件antrun使用if条件标签
date: 2020-08-12 16:54:04
tags: software
---

利用 maven 对项目打包的时候，有时候需要根据条件选择不同的文件或输出到不同路径，因此希望 maven 能够提供 `if` 标签，maven 的 antrun 插件可以提供 `if` 标签。

## antrun 简介

通过 antrun 插件可以在 maven 中运行 ant task，可以在 POM 文件中嵌入 ant 脚本。具体参考 [antrun](http://maven.apache.org/plugins/maven-antrun-plugin)。

## 使用 antrun

可像如下格式使用 antrun

```xml
<project>
  [...]
  <build>
    <plugins>
      <plugin>
        <artifactId>maven-antrun-plugin</artifactId>
        <version>3.0.0</version>
        <executions>
          <execution>
            <phase> <!-- a lifecycle phase --> </phase>
            <configuration>
              <target>

                <!--
                  在这里添加 ant task， 所有能在 ant 的 build.xml 的<target>标签里的都可以出现这里
                -->

              </target>
            </configuration>
            <goals>
              <goal>run</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
  [...]
</project>
```

## 使用 if 标签

要使用 if 标签，需要引入 Ant-Contrib，Ant-Contrib 是 ant 的一个任务集。配置例子如下：

```xml
<project>
  [...]
  <build>
    [...]
    <plugins>
      [...]
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-antrun-plugin</artifactId>
        <version>3.0.0</version>
        <executions>
          <execution>
            [...]
            <configuration>
              <target>
                <!-- 下面这句很重要，ant 会加载 antcontrib.properties 中定义的标签，其中就有 if 标签-->
                <taskdef resource="net/sf/antcontrib/antcontrib.properties" classpathref="maven.plugin.classpath"/>
                [...]
              </target>
            </configuration>
            <goals>
              <goal>run</goal>
            </goals>
          </execution>
        </executions>
        <dependencies>
          <dependency>
            <groupId>ant-contrib</groupId>
            <artifactId>ant-contrib</artifactId>
            <version>1.0b3</version>
            <exclusions>
              <exclusion>
                <groupId>ant</groupId>
                <artifactId>ant</artifactId>
              </exclusion>
            </exclusions>
          </dependency>
        </dependencies>
      </plugin>
    </plugins>
  </build>
</project>
```

注意引入了 ant-contrib 这个倚赖包。

## if 标签的例子

下面是一个根据条件选择不同的文件的例子：

```xml
<configuration>
    <target>
        <taskdef resource="net/sf/antcontrib/antcontrib.properties"
            classpathref="maven.plugin.classpath"/>
        <if>
            <equals arg1="${profileActive}" arg2="local"/>
            <then>
                <copy todir="${project.build.directory}/classes"
                    overwrite="true"><!--执行复制操作,todir的值是将要复制文件到的地方,overwrite是否重写-->
                    <fileset
                        dir="src/main/resources"><!--${project.build.directory}值是你的target目录-->
                        <include name="logback-spring-${profileActive}.xml"/>
                    </fileset>
                </copy>
            </then>
            <else>
                <copy todir="${project.build.directory}/classes"
                    overwrite="true"><!--执行复制操作,todir的值是将要复制文件到的地方,overwrite是否重写-->
                    <fileset
                        dir="src/main/resources"><!--${project.build.directory}值是你的target目录-->
                        <include name="logback-spring.xml"/>
                    </fileset>
                </copy>
            </else>
        </if>
    </target>
</configuration>
```

其中 `<equals arg1="${profileActive}" arg2="local"/>` 的意思是：
arg1 的值等于`${profileActive}`, arg2 的值等于`local`，判断 arg1 是否等于 arg2。

结合`if`标签，就是如果 arg1 等于 arg2，就执行 `then` 标签里面的任务，否则，就执行`else` 标签中的任务。

## if 标签的其它例子

Ant-Contrib 的 `if` 标签还有一些其它用法，例如 `elseif` 标签，例如：

```xml
<if>
 <equals arg1="${foo}" arg2="bar" />
 <then>
   <echo message="The value of property foo is 'bar'" />
 </then>

 <elseif>
  <equals arg1="${foo}" arg2="foo" />
  <then>
   <echo message="The value of property foo is 'foo'" />
  </then>
 </elseif>


 <else>
   <echo message="The value of property foo is not 'foo' or 'bar'" />
 </else>
</if>
```

具体可以参看[文档](http://ant-contrib.sourceforge.net/tasks/tasks/if.html)。
