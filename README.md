# Village Distance Datapack Generator

为 **Minecraft Java 1.20.1 Forge + Structure Essentials** 生成只覆盖原版村庄间距的数据包。

## 为什么需要生成器

Structure Essentials 会在数据包加载之后，对所有 `minecraft:random_spread` 结构放置参数统一乘以 `spacingSeparationModifier`。数据包优先级无法跳过这一步，所以不存在一个能够自动无视任意模组倍率的静态数据包。

这个生成器采用预补偿方式：输入 Structure Essentials 当前倍率和想要的村庄倍率，它会反算数据包应写入的整数参数，使模组乘算后的村庄参数尽量接近目标。它只覆盖 `minecraft:worldgen/structure_set/villages`，不会修改其他结构。

## Windows 使用方法

最简单的方法：

1. 下载本仓库。
2. 双击 `generate_datapack.bat`。
3. 输入 `structureessentials.json` 中当前的 `spacingSeparationModifier`。
4. 成品 ZIP 会出现在 `dist` 文件夹。
5. 把 ZIP 放入服务端的 `world/datapacks`，移除旧版本，然后重启服务端。

也可以直接在 PowerShell 中运行：

```powershell
.\generate_datapack.ps1 -StructureEssentialsMultiplier 2.0
```

自定义村庄目标倍率：

```powershell
.\generate_datapack.ps1 -StructureEssentialsMultiplier 2.0 -VillageTargetMultiplier 3.0
```

## 重要限制

- 修改 Structure Essentials 倍率后，必须用新倍率重新生成数据包并重启服务端。
- 必须在探索新区域前启用；已经生成的村庄不会移动或删除。
- 如果其他数据包也覆盖 `data/minecraft/worldgen/structure_set/villages.json`，只会有一个生效。可用以下指令让生成的数据包处于最后加载位置：

  ```mcfunction
  /datapack enable "file/<生成的文件名>.zip" last
  ```

- 即使加载优先级最高，Structure Essentials 的 Java 乘算仍会执行；本工具通过数值预补偿解决，而不是绕过模组。
- 村庄还受生物群系和地形条件影响，结构放置参数三倍不表示任意两个实际村庄必定保持固定距离。

## 原版基准

Minecraft 1.20.1 原版村庄使用：

| 参数 | 原版值 |
| --- | ---: |
| `spacing` | 34 |
| `separation` | 8 |

生成器会模拟 Structure Essentials 的四舍五入与 `0..4095` 限幅，并确保 `spacing > separation`。
