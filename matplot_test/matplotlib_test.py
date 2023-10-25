import matplotlib.pyplot as plt

# 示例数据
x = [1, 2, 3, 4, 5]  # x轴数据
y = [2, 4, 6, 8, 10]  # y轴数据

# 创建一个折线图
plt.plot(x, y, label='scattering plot', marker='o', linestyle='-', color='b')

# 添加标签和标题
plt.xlabel('X')
plt.ylabel('Y')
plt.title('matplot example')

# 添加图例
plt.legend()
plt.savefig("dp_temp.png") 
# 显示图形
plt.show()