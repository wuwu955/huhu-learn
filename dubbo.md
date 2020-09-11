### Dubbo 源码

#### 一 重要类

```pwd
1.proxyFactory:就是为了获取一个接口的代理类，例如获取一个远程接口的代理。
它有2个方法，代表2个作用
  a.getInvoker:针对server端，将服务对象，如DemoServiceImpl包装成一个Invoker对象。
  b.getProxy  :针对client端，创建接口的代理对象，例如DemoService的接口 包装成一个Invoker对象。
  
2.Wrapper:它类似spring的BeanWrapper,它就是包装了一个接口或一个类，可以通过wrapper对实例对象进行赋值 取值以及制定方法的调用。

3.Invoker：它是一个可执行的对象，能够根据方法的名称、参数得到相应的执行结果。
       它里面有一个很重要的方法 Result invoke(Invocation invocation)，
  Invocation是包含了需要执行的方法和参数等重要信息，目前它只有2个实现类RpcInvocation MockInvocation
      它有3种类型的Invoker
    1.本地执行类的Invoker
    	server端：要执行 demoService.sayHello，就通过InjvmExporter来进行反射执行demoService.sayHello就可以了。
    	
    2.远程通信类的Invoker
        client端：要执行 demoService.sayHello，它封装了DubboInvoker进行远程通信，发送要执行的接口给server端。
        server端：采用了AbstractProxyInvoker执行了DemoServiceImpl.sayHello,然后将执行结果返回发送给client.
        
    3.多个远程通信执行类的Invoker聚合成集群版的Invoker
        client端：要执行 demoService.sayHello，就要通过AbstractClusterInvoker来进行负载均衡，DubboInvoker进行远程通信，发送要执行的接口给server端。
        server端：采用了AbstractProxyInvoker执行了DemoServiceImpl.sayHello,然后将执行结果返回发送给client.
        
4.Protocol
  1.export：暴露远程服务（用于服务端），就是将proxyFactory.getInvoker创建的代理类 invoker对象，通过协议暴露给外部。
  2.refer：引用远程服务（用于客户端）, 通过proxyFactory.getProxy来创建远程的动态代理类 invoker对象，例如DemoService的远程动态接口。
  
5.exporter：维护invoder的生命周期。

6.exchanger：信息交换层，封装请求响应模式，同步转异步。

7.transporter：网络传输层，用来抽象netty和mina的统一接口。

8.Directory：目录服务
  StaticDirectory：静态目录服务，他的Invoker是固定的。
  RegistryDirectory：注册目录服务，他的Invoker集合数据来源于zk注册中心的，他实现了NotifyListener接口，并且实现回调notify(List<URL> urls),
                                                           整个过程有一个重要的map变量，methodInvokerMap（它是数据的来源；同时也是notify的重要操作对象，重点是写操作。）
  
 9 配置timeout
 1 精确优先（method） 全局次之 
 2 消费者优先 提供者次之
```



#### 二 SPI设计

```pwd
为什么要设计adaptive？注解在类上和注解在方法上的区别？
adaptive设计的目的是为了识别固定已知类和扩展未知类。
1.注解在类上：代表人工实现，实现一个装饰类（设计模式中的装饰模式），它主要作用于固定已知类，
  目前整个系统只有2个，AdaptiveCompiler、AdaptiveExtensionFactory。
  a.为什么AdaptiveCompiler这个类是固定已知的？因为整个框架仅支持Javassist和JdkCompiler。
  b.为什么AdaptiveExtensionFactory这个类是固定已知的？因为整个框架仅支持2个objFactory,一个是spi,另一个是spring
2.注解在方法上：代表自动生成和编译一个动态的Adpative类，它主要是用于SPI，因为spi的类是不固定、未知的扩展类，所以设计了动态$Adaptive类.
例如 Protocol的spi类有 injvm dubbo registry filter listener等等 很多扩展未知类，
它设计了Protocol$Adaptive的类，通过ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(spi类);来提取对象

为什么dubbo要自己设计一套SPI？
这是原始JDK spi的代码
	ServiceLoader<Command> serviceLoader=ServiceLoader.load(Command.class); 
  for(Command command:serviceLoader){  
      command.execute();  
  }  
dubbo在原来的基础上设计了以下功能
1.原始JDK spi不支持缓存；dubbo设计了缓存对象：spi的key与value 缓存在 cachedInstances对象里面，它是一个ConcurrentMap
2.原始JDK spi不支持默认值，dubbo设计默认值：@SPI("dubbo") 代表默认的spi对象，例如Protocol的@SPI("dubbo")就是 DubboProtocol，
  通过 ExtensionLoader.getExtensionLoader(Protocol.class).getDefaultExtension()那默认对象
3.jdk要用for循环判断对象，dubbo设计getExtension灵活方便，动态获取spi对象，
  例如 ExtensionLoader.getExtensionLoader(Protocol.class).getExtension(spi的key)来提取对象
4.原始JDK spi不支持 AOP功能，dubbo设计增加了AOP功能,在cachedWrapperClasses，在原始spi类，包装了XxxxFilterWrapper XxxxListenerWrapper
5.原始JDK spi不支持 IOC功能，dubbo设计增加了IOC,通过构造函数注入,代码为：wrapperClass.getConstructor(type).newInstance(instance),


dubbo spi 的目的：获取一个指定实现类的对象。
途径：ExtensionLoader.getExtension(String name)
实现路径：
getExtensionLoader(Class<T> type) 就是为该接口new 一个ExtensionLoader，然后缓存起来。
getAdaptiveExtension() 获取一个扩展类，如果@Adaptive注解在类上就是一个装饰类；如果注解在方法上就是一个动态代理类，例如Protocol$Adaptive对象。
getExtension(String name) 获取一个指定对象。


-----------------------ExtensionLoader.getExtensionLoader(Class<T> type)
ExtensionLoader.getExtensionLoader(Container.class)
  -->this.type = type;
  -->objectFactory = (type == ExtensionFactory.class ? null : ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension());
     -->ExtensionLoader.getExtensionLoader(ExtensionFactory.class).getAdaptiveExtension()
       -->this.type = type;
       -->objectFactory =null;
       
执行以上代码完成了2个属性的初始化
1.每个一个ExtensionLoader都包含了2个值 type 和 objectFactory
  Class<?> type；//构造器  初始化时要得到的接口名
  ExtensionFactory objectFactory//构造器  初始化时 AdaptiveExtensionFactory[SpiExtensionFactory,SpringExtensionFactory]
2.new 一个ExtensionLoader 存储在ConcurrentMap<Class<?>, ExtensionLoader<?>> EXTENSION_LOADERS

关于这个objectFactory的一些细节：
1.objectFactory就是ExtensionFactory，它也是通过ExtensionLoader.getExtensionLoader(ExtensionFactory.class)来实现的，但是它的objectFactory=null
2.objectFactory作用，它就是为dubbo的IOC提供所有对象。
       

-----------------------getAdaptiveExtension()
-->getAdaptiveExtension()//为cachedAdaptiveInstance赋值
  -->createAdaptiveExtension()
    -->getAdaptiveExtensionClass()
      -->getExtensionClasses()//为cachedClasses 赋值
        -->loadExtensionClasses()
          -->loadFile
      -->createAdaptiveExtensionClass()//自动生成和编译一个动态的adpative类，这个类是一个代理类
        -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.common.compiler.Compiler.class).getAdaptiveExtension()
        -->compiler.compile(code, classLoader)
    -->injectExtension()//作用：进入IOC的反转控制模式，实现了动态入注
        
          
关于loadfile的一些细节
目的：通过把配置文件META-INF/dubbo/internal/com.alibaba.dubbo.rpc.Protocol的内容，存储在缓存变量里面。
cachedAdaptiveClass//如果这个class含有adative注解就赋值，例如ExtensionFactory，而例如Protocol在这个环节是没有的。
cachedWrapperClasses//只有当该class无adative注解，并且构造函数包含目标接口（type）类型，
                                                                 例如protocol里面的spi就只有ProtocolFilterWrapper和ProtocolListenerWrapper能命中
cachedActivates//剩下的类，包含Activate注解
cachedNames//剩下的类就存储在这里。

-----------------------getExtension(String name)
getExtension(String name) //指定对象缓存在cachedInstances；get出来的对象wrapper对象，例如protocol就是ProtocolFilterWrapper和ProtocolListenerWrapper其中一个。
  -->createExtension(String name)
    -->getExtensionClasses()
    -->injectExtension(T instance)//dubbo的IOC反转控制，就是从spi和spring里面提取对象赋值。
      -->objectFactory.getExtension(pt, property)
        -->SpiExtensionFactory.getExtension(type, name)
          -->ExtensionLoader.getExtensionLoader(type)
          -->loader.getAdaptiveExtension()
        -->SpringExtensionFactory.getExtension(type, name)
          -->context.getBean(name)
    -->injectExtension((T) wrapperClass.getConstructor(type).newInstance(instance))//AOP的简单设计
    

```

#### 三 服务暴露

```pwd
服务发布-原理
第一个发布的动作：暴露本地服务
	Export dubbo service com.alibaba.dubbo.demo.DemoService to local registry, dubbo version: 2.0.0, current host: 127.0.0.1
第二个发布动作：暴露远程服务
	Export dubbo service com.alibaba.dubbo.demo.DemoService to url 
	Register dubbo service com.alibaba.dubbo.demo.DemoService url 
第三个发布动作：启动netty
	Start NettyServer bind /0.0.0.0:20880, export /192.168.100.38:20880, dubbo version: 2.0.0, current host: 127.0.0.1
第四个发布动作：打开连接zk
	INFO zookeeper.ClientCnxn: Opening socket connection to server /192.168.48.117:2181
第五个发布动作：到zk注册
	Register: dubbo://192.168.100.38:20880/com.alibaba.dubbo.demo.DemoService?anyhost=true&application=demo-provider&dubbo=2.0.0&generic=false&interface=com.alibaba.dubbo.demo.DemoService&loadbalance=roundrobin&methods=sayHello&owner=william&pid=8484&side=provider&timestamp=1473908495465, dubbo version: 2.0.0, current host: 127.0.0.1
第六个发布动作；监听zk
	Subscribe: provider://192.168.100.38:20880/com.alibaba.dubbo.demo.DemoService?anyhost=true&application=demo-provider&category=configurators&check=false&dubbo=2.0.0&generic=false&interface=com.alibaba.dubbo.demo.DemoService&loadbalance=roundrobin&methods=sayHello&owner=william&pid=8484&side=provider&timestamp=1473908495465, dubbo version: 2.0.0, current host: 127.0.0.1
	Notify urls for subscribe url provider://192.168.100.38:20880/com.alibaba.dubbo.demo.DemoService?anyhost=true&application=demo-provider&category=configurators&check=false&dubbo=2.0.0&generic=false&interface=com.alibaba.dubbo.demo.DemoService&loadbalance=roundrobin&methods=sayHello&owner=william&pid=8484&side=provider&timestamp=1473908495465, urls: [empty://192.168.100.38:20880/com.alibaba.dubbo.demo.DemoService?anyhost=true&application=demo-provider&category=configurators&check=false&dubbo=2.0.0&generic=false&interface=com.alibaba.dubbo.demo.DemoService&loadbalance=roundrobin&methods=sayHello&owner=william&pid=8484&side=provider&timestamp=1473908495465], dubbo version: 2.0.0, current host: 127.0.0.1

暴露本地服务和暴露远程服务的区别是什么？
1.暴露本地服务：指暴露在用一个JVM里面，不用通过调用zk来进行远程通信。例如：在同一个服务，自己调用自己的接口，就没必要进行网络IP连接来通信。
2.暴露远程服务：指暴露给远程客户端的IP和端口号，通过网络来实现通信。

zk持久化节点 和临时节点有什么区别？
持久化节点：一旦被创建，触发主动删除掉，否则就一直存储在ZK里面。
临时节点：与客户端会话绑定，一旦客户端会话失效，这个客户端端所创建的所有临时节点都会被删除。

ServiceBean.onApplicationEvent
-->export()
  -->ServiceConfig.export()
    -->doExport()
      -->doExportUrls()//里面有一个for循环，代表了一个服务可以有多个通信协议，例如 tcp协议 http协议，默认是tcp协议
        -->loadRegistries(true)//从dubbo.properties里面组装registry的url信息
        -->doExportUrlsFor1Protocol(ProtocolConfig protocolConfig, List<URL> registryURLs) 
          //配置不是remote的情况下做本地暴露 (配置为remote，则表示只暴露远程服务)
          -->exportLocal(URL url)
            -->proxyFactory.getInvoker(ref, (Class) interfaceClass, local)
              -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.ProxyFactory.class).getExtension("javassist");
              -->extension.getInvoker(arg0, arg1, arg2)
                -->StubProxyFactoryWrapper.getInvoker(T proxy, Class<T> type, URL url) 
                  -->proxyFactory.getInvoker(proxy, type, url)
                    -->JavassistProxyFactory.getInvoker(T proxy, Class<T> type, URL url)
                      -->Wrapper.getWrapper(com.alibaba.dubbo.demo.provider.DemoServiceImpl)
                        -->makeWrapper(Class<?> c)
                      -->return new AbstractProxyInvoker<T>(proxy, type, url)
            -->protocol.export
              -->Protocol$Adpative.export
                -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.Protocol.class).getExtension("injvm");
                -->extension.export(arg0)
                  -->ProtocolFilterWrapper.export
                    -->buildInvokerChain //创建8个filter
                    -->ProtocolListenerWrapper.export
                      -->InjvmProtocol.export
                        -->return new InjvmExporter<T>(invoker, invoker.getUrl().getServiceKey(), exporterMap)
                        -->目的：exporterMap.put(key, this)//key=com.alibaba.dubbo.demo.DemoService, this=InjvmExporter
          //如果配置不是local则暴露为远程服务.(配置为local，则表示只暴露本地服务)
          -->proxyFactory.getInvoker//原理和本地暴露一样都是为了获取一个Invoker对象
          -->protocol.export(invoker)
            -->Protocol$Adpative.export
              -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.Protocol.class).getExtension("registry");
	            -->extension.export(arg0)
	              -->ProtocolFilterWrapper.export
	                -->ProtocolListenerWrapper.export
	                  -->RegistryProtocol.export
	                    -->doLocalExport(originInvoker)
	                      -->getCacheKey(originInvoker);//读取 dubbo://192.168.100.51:20880/
	                      -->protocol.export
	                        -->Protocol$Adpative.export
	                          -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.Protocol.class).getExtension("dubbo");
	                          -->extension.export(arg0)
	                            -->ProtocolFilterWrapper.export
	                              -->buildInvokerChain//创建8个filter
	                              -->ProtocolListenerWrapper.export
---------1.netty服务暴露的开始-------    -->DubboProtocol.export
	                                  -->serviceKey(url)//组装key=com.alibaba.dubbo.demo.DemoService:20880
	                                  -->目的：exporterMap.put(key, this)//key=com.alibaba.dubbo.demo.DemoService:20880, this=DubboExporter
	                                  -->openServer(url)
	                                    -->createServer(url)
--------2.信息交换层 exchanger 开始-------------->Exchangers.bind(url, requestHandler)//exchaanger是一个信息交换层
	                                        -->getExchanger(url)
	                                          -->getExchanger(type)
	                                            -->ExtensionLoader.getExtensionLoader(Exchanger.class).getExtension("header")
	                                        -->HeaderExchanger.bind
	                                          -->Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler)))
	                                            -->new HeaderExchangeHandler(handler)//this.handler = handler
	                                            -->new DecodeHandler
	                                            	-->new AbstractChannelHandlerDelegate//this.handler = handler;
---------3.网络传输层 transporter--------------------->Transporters.bind
	                                              -->getTransporter()
	                                                -->ExtensionLoader.getExtensionLoader(Transporter.class).getAdaptiveExtension()
	                                              -->Transporter$Adpative.bind
	                                                -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.remoting.Transporter.class).getExtension("netty");
	                                                -->extension.bind(arg0, arg1)
	                                                  -->NettyTransporter.bind
	                                                    --new NettyServer(url, listener)
	                                                      -->AbstractPeer //this.url = url;    this.handler = handler;
	                                                      -->AbstractEndpoint//codec  timeout=1000  connectTimeout=3000
	                                                      -->AbstractServer //bindAddress accepts=0 idleTimeout=600000
---------4.打开端口，暴露netty服务-------------------------------->doOpen()
	                                                        -->设置 NioServerSocketChannelFactory boss worker的线程池 线程个数为3
	                                                        -->设置编解码 hander
	                                                        -->bootstrap.bind(getBindAddress())
	                                            -->new HeaderExchangeServer
	                                              -->this.server=NettyServer
	                                              -->heartbeat=60000
	                                              -->heartbeatTimeout=180000
	                                              -->startHeatbeatTimer()//这是一个心跳定时器，采用了线程池，如果断开就心跳重连。

	                    -->getRegistry(originInvoker)//zk 连接
	                      -->registryFactory.getRegistry(registryUrl)
	                        -->ExtensionLoader.getExtensionLoader(RegistryFactory.class).getExtension("zookeeper");
	                        -->extension.getRegistry(arg0)
	                          -->AbstractRegistryFactory.getRegistry//创建一个注册中心，存储在REGISTRIES
	                            -->createRegistry(url)
	                              -->new ZookeeperRegistry(url, zookeeperTransporter)
	                                -->AbstractRegistry
	                                  -->loadProperties()//目的：把C:\Users\bobo\.dubbo\dubbo-registry-192.168.48.117.cache
	                                                                                                                                                                    文件中的内容加载为properties
	                                  -->notify(url.getBackupUrls())//不做任何事             
	                                -->FailbackRegistry   
	                                  -->retryExecutor.scheduleWithFixedDelay(new Runnable()//建立线程池，检测并连接注册中心,如果失败了就重连
	                                -->ZookeeperRegistry
	                                  -->zookeeperTransporter.connect(url)
	                                    -->ZookeeperTransporter$Adpative.connect(url)
	                                      -->ExtensionLoader.getExtensionLoader(ZookeeperTransporter.class).getExtension("zkclient");
	                                      -->extension.connect(arg0)
	                                        -->ZkclientZookeeperTransporter.connect
	                                          -->new ZkclientZookeeperClient(url)
	                                            -->AbstractZookeeperClient
	                                            -->ZkclientZookeeperClient
	                                              -->new ZkClient(url.getBackupAddress());//连接ZK
	                                              -->client.subscribeStateChanges(new IZkStateListener()//订阅的目标：连接断开，重连
	                                    -->zkClient.addStateListener(new StateListener() 
	                                      -->recover //连接失败 重连
	                                      
	                    -->registry.register(registedProviderUrl)//创建节点
	                      -->AbstractRegistry.register
	                      -->FailbackRegistry.register
	                        -->doRegister(url)//向zk服务器端发送注册请求
	                          -->ZookeeperRegistry.doRegister
	                            -->zkClient.create
	                              -->AbstractZookeeperClient.create//dubbo/com.alibaba.dubbo.demo.DemoService/providers/
										                              dubbo%3A%2F%2F192.168.100.52%3A20880%2Fcom.alibaba.dubbo.demo.DemoService%3Fanyhost%3Dtrue%26
										                              application%3Ddemo-provider%26dubbo%3D2.0.0%26generic%3Dfalse%26interface%3D
										                              com.alibaba.dubbo.demo.DemoService%26loadbalance%3Droundrobin%26methods%3DsayHello%26owner%3
										                              Dwilliam%26pid%3D2416%26side%3Dprovider%26timestamp%3D1474276306353
	                                -->createEphemeral(path);//临时节点  dubbo%3A%2F%2F192.168.100.52%3A20880%2F.............
	                                -->createPersistent(path);//持久化节点 dubbo/com.alibaba.dubbo.demo.DemoService/providers                 
	                                    
	                    -->registry.subscribe//订阅ZK
	                      -->AbstractRegistry.subscribe
	                      -->FailbackRegistry.subscribe
	                        -->doSubscribe(url, listener)// 向服务器端发送订阅请求
	                          -->ZookeeperRegistry.doSubscribe
	                            -->new ChildListener()
	                              -->实现了 childChanged
	                                -->实现并执行 ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds));
	                              //A
	                            -->zkClient.create(path, false);//第一步：先创建持久化节点/dubbo/com.alibaba.dubbo.demo.DemoService/configurators
	                            -->zkClient.addChildListener(path, zkListener)
	                              -->AbstractZookeeperClient.addChildListener
	                                //C
	                                -->createTargetChildListener(path, listener)//第三步：收到订阅后的处理，交给FailbackRegistry.notify处理
	                                  -->ZkclientZookeeperClient.createTargetChildListener
	                                    -->new IZkChildListener() 
	                                      -->实现了 handleChildChange //收到订阅后的处理
	                                      	-->listener.childChanged(parentPath, currentChilds);
	                                      	-->实现并执行ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds));
	                                      	-->收到订阅后处理 FailbackRegistry.notify
	                                //B      	
	                                -->addTargetChildListener(path, targetListener)////第二步
	                                  -->ZkclientZookeeperClient.addTargetChildListener
	                                    -->client.subscribeChildChanges(path, listener)//第二步：启动加入订阅/dubbo/com.alibaba.dubbo.demo.DemoService/configurators
	                    
	                    -->notify(url, listener, urls)
	                      -->FailbackRegistry.notify
	                        -->doNotify(url, listener, urls);
	                          -->AbstractRegistry.notify
	                            -->saveProperties(url);//把服务端的注册url信息更新到C:\Users\bobo\.dubbo\dubbo-registry-192.168.48.117.cache
	                              -->registryCacheExecutor.execute(new SaveProperties(version));//采用线程池来处理
	                            -->listener.notify(categoryList)
	                              -->RegistryProtocol.notify
	                                -->RegistryProtocol.this.getProviderUrl(originInvoker)//通过invoker的url 获取 providerUrl的地址
	                                                                                                        
		                                       
```

#### 四 服务引用

```pwd
ReferenceBean.getObject()
  -->ReferenceConfig.get()
    -->init()
      -->createProxy(map)
        -->refprotocol.refer(interfaceClass, urls.get(0))
          -->ExtensionLoader.getExtensionLoader(Protocol.class).getExtension("registry");
          -->extension.refer(arg0, arg1);
            -->ProtocolFilterWrapper.refer
              -->RegistryProtocol.refer
                -->registryFactory.getRegistry(url)//建立zk的连接，和服务端发布一样（省略代码）
                -->doRefer(cluster, registry, type, url)
                  -->registry.register//创建zk的节点，和服务端发布一样（省略代码）。节点名为：dubbo/com.alibaba.dubbo.demo.DemoService/consumers
                  -->registry.subscribe//订阅zk的节点，和服务端发布一样（省略代码）。   /dubbo/com.alibaba.dubbo.demo.DemoService/providers, 
                                                                        /dubbo/com.alibaba.dubbo.demo.DemoService/configurators,
                                                                         /dubbo/com.alibaba.dubbo.demo.DemoService/routers]
                    -->notify(url, listener, urls);
                      -->FailbackRegistry.notify
                        -->doNotify(url, listener, urls);
                          -->AbstractRegistry.notify
                            -->saveProperties(url);//把服务端的注册url信息更新到C:\Users\bobo\.dubbo\dubbo-registry-192.168.48.117.cache
	                          -->registryCacheExecutor.execute(new SaveProperties(version));//采用线程池来处理
	                        -->listener.notify(categoryList)
	                          -->RegistryDirectory.notify
	                            -->refreshInvoker(invokerUrls)//刷新缓存中的invoker列表
	                              -->destroyUnusedInvokers(oldUrlInvokerMap,newUrlInvokerMap); // 关闭未使用的Invoker
	                              -->最终目的：刷新Map<String, Invoker<T>> urlInvokerMap 对象
	                                                                                                                       刷新Map<String, List<Invoker<T>>> methodInvokerMap对象
                  -->cluster.join(directory)//加入集群路由
                    -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.cluster.Cluster.class).getExtension("failover");
                      -->MockClusterWrapper.join
                        -->this.cluster.join(directory)
                          -->FailoverCluster.join
                            -->return new FailoverClusterInvoker<T>(directory)
                            -->new MockClusterInvoker
        -->proxyFactory.getProxy(invoker)//创建服务代理
          -->ProxyFactory$Adpative.getProxy
            -->ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.ProxyFactory.class).getExtension("javassist");
              -->StubProxyFactoryWrapper.getProxy
                -->proxyFactory.getProxy(invoker)
                  -->AbstractProxyFactory.getProxy
                    -->getProxy(invoker, interfaces)
                      -->Proxy.getProxy(interfaces)//目前代理对象interface com.alibaba.dubbo.demo.DemoService, interface com.alibaba.dubbo.rpc.service.EchoService
                      -->InvokerInvocationHandler// 采用jdk自带的InvocationHandler，创建InvokerInvocationHandler对象。
	                          
	                          
                    
  
```



#### 五 关键类

```pwd
1 路径匹配类 UrlUtils isMatch 匹配消费者的 * 提供者配* 消费者 也得配*
2 缓存本地文件 AbstractRegistry doSaveProperties
3ExtensionLoader.getExtensionLoader(com.alibaba.dubbo.rpc.Protocol.class).getExtension("registry"); 怎么获取流程
4 服务  http://dubbo.apache.org/zh-cn/docs/dev/design.html

   

```

#### 六 消费者请求流程

```pwd
demoService.sayHello("world" + i)
-->InvokerInvocationHandler.invoke
  -->invoker.invoke
    -->RpcInvocation//所有请求参数都会转换为RpcInvocation
    -->MockClusterInvoker.invoke //1.进入集群
      -->invoker.invoke(invocation)
        -->AbstractClusterInvoker.invoke
          -->list(invocation)
            -->directory.list//2.进入目录查找   从this.methodInvokerMap里面查找一个Invoker
              -->AbstractDirectory.list
                -->doList(invocation)
                  -->RegistryDirectory.doList// 从this.methodInvokerMap里面查找一个Invoker
                -->router.route //3.进入路由 
                  -->MockInvokersSelector.route
                    -->getNormalInvokers
          -->ExtensionLoader.getExtensionLoader(LoadBalance.class).getExtension("roundrobin")
          -->doInvoke
            -->FailoverClusterInvoker.doInvoke
              -->select//4.进入负载均衡
                -->AbstractClusterInvoker.select
                  -->doselect
                    -->loadbalance.select
                      -->AbstractLoadBalance.select
                        -->doSelect
                          -->RoundRobinLoadBalance.doSelect
                            -->invokers.get(currentSequence % length)//取模轮循
              -->Result result = invoker.invoke(invocation)
--------------------------------------------------------------------------扩展点----------------
                -->InvokerWrapper.invoke // 在把url 转换成invoke 的时候 用 这个类InvokerDelegete去包装了
                  -->ProtocolFilterWrapper.invoke
                    -->ConsumerContextFilter.invoke 
                      -->ProtocolFilterWrapper.invoke
                        -->MonitorFilter.invoke
                          -->ProtocolFilterWrapper.invoke
                            -->FutureFilter.invoke
                              -->ListenerInvokerWrapper.invoke
                                -->AbstractInvoker.invoke
---------------------------------------------------------------------------扩展点---------------
                                  -->doInvoke(invocation)
                                    -->DubboInvoker.doInvoke//为什么DubboInvoker是个protocol? 因为RegistryDirectory.refreshInvoker.toInvokers： protocol.refer
                                      -->ReferenceCountExchangeClient.request
                                        -->HeaderExchangeClient.request
                                          -->HeaderExchangeChannel.request
                                            -->NettyClient.send
                                            -->AbstractPeer.send
                                              -->NettyChannel.send
                                                -->ChannelFuture future = channel.write(message);//最终的目的：通过netty的channel发送网络数据
//consumer的接收原理 
NettyHandler.messageReceived
  -->AbstractPeer.received
    -->MultiMessageHandler.received
      -->HeartbeatHandler.received
        -->AllChannelHandler.received
          -->ChannelEventRunnable.run //线程池 执行线程
            -->DecodeHandler.received
              -->HeaderExchangeHandler.received
                -->handleResponse(channel, (Response) message);
                  -->HeaderExchangeHandler.handleResponse
                    -->DefaultFuture.received
                      -->DefaultFuture.doReceived
                        private void doReceived(Response res) {
					        lock.lock();
					        try {
					            response = res;
					            if (done != null) {
					                done.signal();
					            }
					        } finally {
					            lock.unlock();
					        }
					        if (callback != null) {
					            invokeCallback(callback);
					        }
					    }

灰度发布例子：
provider  192.168.100.38    192.168.48.32
1.发布192.168.48.32，切断192.168.48.32访问流量，然后进行服务的发布。
2.192.168.48.32发布成功后，恢复 192.168.48.32的流量，

3.切断192.168.100.38，继续发布 192.168.100.38
                  
2个疑问
1.启动路由规则，它触发了那些动作？
  a.什么时候加入ConditionRouter？
  b.ConditionRouter是怎么过滤的？
2.路由规则有哪些实现类？    
ConditionRouter：条件路由，后台管理的路由配置都是条件路由。
ScriptRouter：脚本路由       
            
流程描述
1 先InvokerInvocationHandler 进行包装处理
2 进入MockClusterInvoker 看有没有配置Mock(force fail) 服务降级规则
3 AbstractClusterInvoker 在这个类中获取所有的invokes 和 负载均衡策略LoadBalance 
  调用 AbstractDirectory ->RegistryDirectory dolist(从Map中获取) toInvokers  been refer 进行 InvokerDelegate 包装成 InvokerWrapper 
  调用 doInvoke 根据 Apdate 获取集群容错的策略
4 调用 FailoverClusterInvoker（默认失败重试） 的 doInvoke  其中 select——>doselect ->loadbalance
  采用负载均衡策略LoadBalance 的对象方法 然后在 invoke
5 InvokerWrapper.invoke ProtocolFilterWrapper buildInvokerChain 进入过滤器链
6 ConsumerContextFilter 设置RpcContext MonitorFilter FutureFilter 是否是异步调用
7 AbstractInvoker ->DubboInvoker.doinvoke 
8 netty 的发送和接收
```

#### 七 服务提供者响应流程

```pwd
NettyHandler.messageReceived
  -->AbstractPeer.received
    -->MultiMessageHandler.received
      -->HeartbeatHandler.received
        -->AllChannelHandler.received
          -->ChannelEventRunnable.run //线程池 执行线程
            -->DecodeHandler.received
              -->HeaderExchangeHandler.received
                -->handleRequest(exchangeChannel, request)//网络通信接收处理 
                  -->DubboProtocol.reply
                    -->getInvoker
                      -->exporterMap.get(serviceKey)//从服务暴露里面提取 
                      -->DubboExporter.getInvoker()//最终得到一个invoker
-------------------------------------------------------------------------扩展点--------------
                    -->ProtocolFilterWrapper.invoke
                      -->EchoFilter.invoke
                        -->ClassLoaderFilter.invoke
                          -->GenericFilter.invoke
                            -->TraceFilter.invoke
                              -->MonitorFilter.invoke
                                -->TimeoutFilter.invoke
                                  -->ExceptionFilter.invoke
                                    -->InvokerWrapper.invoke
-------------------------------------------------------------------------扩展点--------------
                                      -->AbstractProxyInvoker.invoke
                                        -->JavassistProxyFactory.AbstractProxyInvoker.doInvoke
                                          --> 进入真正执行的实现类   DemoServiceImpl.sayHello
                                        ....................................
                -->channel.send(response);//把接收处理的结果，发送回去 
                  -->AbstractPeer.send
                    -->NettyChannel.send
                      -->ChannelFuture future = channel.write(message);//数据发回consumer
                      

```

#### 八 异步和同步

```pwd
dubbo 是基于netty NIO的非阻塞 并行调用通信。 （阻塞  非阻塞  异步  同步 区别 ）
dubbo 的通信方式 有3类类型：

1.异步，有返回值
	<dubbo:method name="sayHello" async="true"></dubbo:method>
	Future<String> temp= RpcContext.getContext().getFuture();
    hello=temp.get();
2.异步，无返回值
	<dubbo:method name="sayHello" return="false"></dubbo:method>

3.异步，变同步（默认的通信方式）
  A.当前线程怎么让它 “暂停，等结果回来后，再执行”？
  B.socket是一个全双工的通信方式，那么在多线程的情况下，如何知道那个返回结果对应原先那条线程的调用？
    	通过一个全局唯一的ID来做consumer 和 provider 来回传输。
  


```

#### 九 编解码

```pwd
tcp 为什么会出现粘包 拆包的问题？
1.消息的定长，例如定1000个字节
2.就是在包尾增加回车或空格等特殊字符作为切割，典型的FTP协议
3.将消息分为消息头消息体。例如 dubbo


----------1------consumer请求编码----------------------
-->NettyCodecAdapter.InternalEncoder.encode
  -->DubboCountCodec.encode
    -->ExchangeCodec.encode
      -->ExchangeCodec.encodeRequest
        -->DubboCodec.encodeRequestData
dubbo的消息头是一个定长的 16个字节。
第1-2个字节：是一个魔数数字：就是一个固定的数字 
第3个字节：是双向(有去有回) 或单向（有去无回）的标记 
第四个字节：？？？ （request 没有第四个字节）
第5-12个字节：请求id：long型8个字节。异步变同步的全局唯一ID，用来做consumer和provider的来回通信标记。
第13-16个字节：消息体的长度，也就是消息头+请求数据的长度。

----------2------provider 请求解码----------------------
--NettyCodecAdapter.InternalDecoder.messageReceived
  -->DubboCountCodec.decode
    -->ExchangeCodec.decode
      -->ExchangeCodec.decodeBody

----------3------provider响应结果编码----------------------
-->NettyCodecAdapter.InternalEncoder.encode
  -->DubboCountCodec.encode
    -->ExchangeCodec.encode
      -->ExchangeCodec.encodeResponse
        -->DubboCodec.encodeResponseData//先写入一个字节 这个字节可能是RESPONSE_NULL_VALUE  RESPONSE_VALUE  RESPONSE_WITH_EXCEPTION
dubbo的消息头是一个定长的 16个字节。
第1-2个字节：是一个魔数数字：就是一个固定的数字 
第3个字节：序列号组件类型，它用于和客户端约定的序列号编码号
第四个字节：它是response的结果响应码  例如 OK=20
第5-12个字节：请求id：long型8个字节。异步变同步的全局唯一ID，用来做consumer和provider的来回通信标记。
第13-16个字节：消息体的长度，也就是消息头+请求数据的长度。

----------4------consumer响应结果解码----------------------
--NettyCodecAdapter.InternalDecoder.messageReceived
  -->DubboCountCodec.decode
    -->ExchangeCodec.decode
      -->DubboCodec.decodeBody
        -->DecodeableRpcResult.decode//根据RESPONSE_NULL_VALUE  RESPONSE_VALUE  RESPONSE_WITH_EXCEPTION进行响应的处理


```

#### 十 动态代码模板

```java

package <扩展点接口所在包>;
public class <扩展点接口名>$Adpative implements <扩展点接口> {
    public <有@Adaptive注解的接口方法>(<方法参数>) {
        if(是否有URL类型方法参数?) 使用该URL参数
        else if(是否有方法类型上有URL属性) 使用该URL属性
        # <else 在加载扩展点生成自适应扩展点类时抛异常，即加载扩展点失败！>
         
        if(获取的URL == null) {
            throw new IllegalArgumentException("url == null");
        }
 
              根据@Adaptive注解上声明的Key的顺序，从URL获致Value，作为实际扩展点名。
               如URL没有Value，则使用缺省扩展点实现。如没有扩展点， throw new IllegalStateException("Fail to get extension");
 
               在扩展点实现调用该方法，并返回结果。
    }
 
    public <有@Adaptive注解的接口方法>(<方法参数>) {
        throw new UnsupportedOperationException("is not adaptive method!");
    }
}



```

