### Lua 实践

#### 2020-05-05

```lua
#安装
1 http://www.lua.org/download.html
2 make macosx sudo make install
3 lua  print('hello world')
#lua 应用项目
https://github.com/ZhuBaker/redis-lua
https://github.com/ZhuBaker/rate-limiter
#逻辑语句
a and b -- 如果 a 为 false，则返回 a，否则返回 b
a or b -- 如果a为true，则返回a，否则返回b
a =a or 0; //如果a 为false 就赋值0
#循环 
-- 数组对象
 days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
 -- i:索引 v:值
for i,v in ipairs(days) do
print(v);
end
>lua hello.lua 
#函数
function pr_days()
	local days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
    -- i:索引 v:值
    for i,v in ipairs(days) do
        print(v);
    end-- body
end
function f(a, b) 
	return a or b 
end
  //多个返回值的
  function pr_max(a)
local mi = 1
local m = a[mi] 
for i,val in ipairs(a) do
 if val > m then
  mi = i
  m = val
 end 
end
   return m, mi
end

//调用
 >dofile 'hello.lua ' 
 >pr_days() //...
 >f(1,2) //1 
 > pr_max({1,2,7,2}) // 7 3

```

