local WikiDesc = {
    -- 机制
    generation = {
        world = {
            name = "世界设置",
            intro = [[本mod中只保留了[海难]和[哈姆雷特]部分，
                    玩家可以在同一个世界中同时游玩联机原版内容，
                    海难和哈姆雷特的内容（[无需跳世界]）。
                    ----------------
                    世界的默认出生区域为[哈姆雷特]。
                    大理石布景会在全图随机刷新。
                    其他布景，如舞台之手，拾荒疯猪，小丑牌等内容会刷新在出生地所在的区域。
                    ----------------
                    客户端生成世界时，请通过[森林、洞穴设置界面]进行调整。
                    服务器开服时，没有相关设置，请通过[客户端生成世界]，再上传至服务器。]]
        },
        seasons = {
            name = "季节",
            intro = [[季节随着[地区变化]，巨人国地区为春夏秋冬，
                    海难地区为平风雨旱，
                    哈姆雷特为温和、雾季、繁茂季。
                    ----------------
                    [滤镜]、[音乐]等会随着地区和季节进行切换。]]
        },

        bundled_structure = {
            intro = [[将[playerhouse_city]或者其他带有内部空间的[商店]
                    通过[锤击]打包成[bundled_structure]。
                    [bundled_structure]会保存所有房屋中的物品。
                    ----------------
                    重新将[bundled_structure]放置在地上即可获得之前的房产，实现房屋搬迁。
                    注意！！！这个操作[不能跨世界]。
            ]]
        },

        house_extension = {
            name = "房屋扩建",
            intro = [[在[playerhouse_city]室内，可通过[室内科技]消耗[oinc]制作多种风格的房门（如[wood_door]、[curtain_door]、[iron_door]、[stone_door]等）。
                    ----------------
                    【多向拓展】：房门可以建造在房间的后墙、左墙或右墙（甚至前墙连通室外出口），打破了以往单一朝向与树状结构的限制，支持在多方向网格化开辟房间。
                    ----------------
                    【开辟与继承】：
                    1. 房间连通：若朝向已有相邻房间，放置房门后将自动双向互通。
                    2. 新辟空间：若朝向尚未开辟房间，将[construction_permit]给予未连接的门扉即可开辟全新扩展房间。
                    3. 动态继承：新开辟的扩展房间彻底重构，自动继承主房屋的规格尺寸（长宽）、地皮与墙面材质风格、边界轮廓及专属室内镜头配置，不再是局促固定的微型预设。
                    ----------------
                    【拆除与装修】：
                    1. 家具拆解：室内生成的所有原生固定家具（货架壁柜、装饰灯具、墙面挂饰等）均支持使用普通[hammer]直接敲击拆除，货架拆除时存放的物品会安全掉落，无需任何许可即可腾出自由装修空间。
                    2. 房间拆除：若要拆除末端扩展房间，只需将[demolition_permit]给予该房间中心的控制信标，即可安全拆除整间扩展房，房内玩家会自动安全移出至相连房间。门扉自身也支持使用[hammer]直接敲除。
                    ----------------
                    【小地图与视角】：室内小地图与游戏 HUD 边框自适应对齐，踏入新房间时自动解除迷雾并点亮该区域；墙面挂画、窗户等在建造时支持上下调整高度，且深度层级与墙体完美贴合。]]
        },

        volcano = {
            name = "火山与喷发",
            intro = [[火山作为深海中的[独立岛屿]存在。内部拥有火山祭坛、黑曜石矿藏、仙人掌与珍贵的[coffeebeans]（咖啡树）生态。
                    ----------------
                    【高温环境】：火山岛内部环境温度显著高于其他地区，常年酷热，需常备防暑与降温装备。
                    ----------------
                    【旱季活跃与预警】：进入海难[旱季]（Dry Season）后，火山将进入活跃期；大喷发前夕会经历数次地壳震颤、火山灰降落与浓烟漫天的多阶段预警。
                    ----------------
                    【龙蛋流星雨】：预警结束后火山将剧烈爆发，天空降下密集的燃烧龙蛋流星雨（Dragonegg Meteor Rain），对地面目标造成范围毁灭性打击、点燃植被，并遗留熔岩或孵化出熔岩猎犬幼崽。
                    ----------------
                    【祭坛平息】：可在火山内部的[volcano_altar]（火山祭坛）投入鸟蛋、[obsidian]、怪兽肉等贡品延长平静期或平息喷发；严禁投入杂物。]]
        },
        waves = {
            name = "海浪",
            intro = [[海浪会拍动[船]，但是更好的船只和[保险杠]会降低海浪的影响，
                    各种船和保险杠的破浪效率，详见[船（联机）]部分介绍。]]
        },

        floods = {
            name = "洪水与积水",
            intro = [[海难与哈姆雷特雨季/季风季节（Monsoon Season）的核心生存挑战。
                    ----------------
                    【水坑蔓延】：随着雨季降雨持续，地表低洼处会涌现并向外逐渐扩张积水水坑（Puddles），直至雨季后期达到最大范围。
                    ----------------
                    【恶劣影响】：
                    1. 移动减速与潮湿：玩家行走在积水上会导致移动速度大幅下降，且潮湿度迅速飙升。
                    2. 设施失灵：积水一旦蔓延至营地，被淹没（flooded）的烹饪锅、科学仪器、冰箱、熔炉等科技设施会短路冒烟并暂时停止工作。
                    3. 滋生毒蚊：积水水坑会定期滋生[mosquito_poison]（毒蚊子），对基地成员构成严重骚扰与中毒威胁。
                    ----------------
                    【防御与消退】：在设施周围及水坑边缘提前建造[sandbag_item]（沙袋）可阻断洪水蔓延扩张；季风雨季结束后，积水会随着干旱晴天逐渐蒸发消退，被淹设施恢复运转。]]
        },
        ruins = {
            name = "遗迹",
            intro = [[遗迹不再是地上生成的房间迷宫，而是[生成在地下]，重构为与远古[档案馆]类似的广袤地下迷宫系统。
                    ----------------
                    入口许愿井旁每15天会刷新一只[ancient_herald]。
                    迷宫内分布有长廊、十字交叉路口、守卫房与密室，包含飞镖雕像（联动玄武岩采矿触发、耗尽具有专属外观）、地刺陷阱与沉睡踏板等危险机关，深处通往[aporkalypse_clock]；严格限制穿墙瞬移以保护探索体验。
                    ----------------
                    遗迹附近的[CAVE_EXIT]通向[蛇岛（兼毒岛）]。通过地下的哈姆雷特地区，与联机洞穴的[绿蘑菇林]相连接。]]
        },

        anthill = {
            name = "蚁穴",
            intro = [[蚁穴不再是地上生成的房间迷宫，而是洞穴中的一片区域。
                    ----------------
                    蚁穴附近的[CAVE_EXIT]通向[皇城]。通过地下哈姆雷特地区与联机洞穴的[绿蘑菇林]相连接。]]
        },

        aporkalypse = {
            name = "毁灭季",
            intro = [[默认情况下，世界天数120天时会开启毁灭季。
                    毁灭季降临时世界都会变为血红色。
                    [地下]每过一段时间会生成[ancient_herald]和[vampirebat]，[地上]只会生成[vampirebat]。
                    ----------------
                    [aporkalypse_clock]在洞穴的[哈姆雷特遗迹迷宫]深处，通过转动[aporkalypse_clock]停止毁灭季。
                    ----------------
                    已经与[独行长路]兼容。]]
        },

        bermudatriangle = {
            name = "电光三角",
            intro = [[生成于深海区域的成对神秘时空漩涡（百慕大三角）。
                    ----------------
                    驾驶[单人船]航行穿过或点击跳入时，伴随雷电风暴与海浪音效平滑传送到另一端的电光三角海域。
                    全面接入实体有效性校验与脱船保护，彻底修复了跨海传送时角色脱船掉入深海溺水的问题。]]
        },

        ocean_boundary = {
            name = "海洋无缝环绕",
            intro = [[还原单机海难经典的大航海环绕机制。
                    ----------------
                    无论是驾驶单人船还是多人大船，当航行至世界地图边缘时不再被虚空阻挡撞墙，而是触发专属近海迷雾与镜头转场，平滑无缝地从正对侧海域边缘穿出，实现星球环状航海体验。]]
        },
    },

    -- 建筑类 (含所有商店)
    structures = {
        pugalisk_fountain = {
            intro = [[ [月圆时]如果世界中不存在存活的[pugalisk]，月光则会重新充盈[pugalisk_fountain]，
                    玩家从[pugalisk_fountain]取走[waterdrop]后，[pugalisk_fountain]会生成一只[pugalisk]。
                    ----------------
                    [waterdrop]可种植，有回复精神值效果。
                    ----------------
                    击杀[pugalisk]会掉落[pugalisk_fountain]的制作蓝图。
                    ----------------
                    人工制作的[pugalisk_fountain]有更强大的力量，效果包括降温，避雷避雨和回复精神值。]]
        },
        pig_palace = {
            intro = [[主殿内的[pigman_queen]可以进行交易换取[pedestal_key]。
                    可使用[pedestal_key]在侧殿的展柜换取一系列珍惜道具。
                    例如[key_to_city]，[city_hammer]，[TRINKET_GIFTSHOP_4]。]]
        },
        pig_shop_cityhall = {
            intro = [[[pigman_mayor]作为交易NPC，接受[goldnugget]、[oinc]、[dubloon]等材料。
                    ----------------
                    在市政厅内也可通过展柜换取[deed]、[securitycontract]等内容。]]
        },
        playerhouse_city = {
            intro = [[室内可通过[室内科技]制作物品，对房屋的内饰和外观进行升级。也可在墙面建造各类门扉进行[house_extension]（房屋扩建）。]]
        },
        pig_shop_deli = {
            intro = [[售卖高级料理。包括[ratatouille]、[meatballs]以及昂贵的[dragonpie]。
                    ----------------
                    是储备高性价比食物的好去处。]]
        },
        pig_shop_general = {
            intro = [[提供基础工具。售卖[axe]、[pickaxe]、[minerhat]以及[umbrella]。
                    ----------------
                    同时也出售[fabric]、[flint]等常用生活物资。]]
        },
        pig_shop_hoofspa = {
            intro = [[城镇药店。提供[healingsalve]、[bandage]和[antivenom]。
                    ----------------
                    如果你有足够的钱，甚至能买到[lifeinjector]。]]
        },
        pig_shop_produce = {
            intro = [[售卖新鲜的食材，如[meat]、[eggplant]、[pumpkin]和[watermelon]。
                    ----------------
                    适合买回营地配合烹饪锅制作料理。]]
        },
        pig_shop_florist = {
            intro = [[售卖植物种子和草木。包括[corn_seeds]、[pumpkin_seeds]和[dug_berrybush]。
                    ----------------
                    这里也提供[flowerhat]和各色装饰性植物。]]
        },
        pig_shop_antiquities = {
            intro = [[哈姆雷特最珍贵的商店。售卖[gears]、[mandrake]和[deerclops_eyeball]。
                    ----------------
                    甚至能直接买到[dragon_scales]等BOSS掉落物。]]
        },
        pig_shop_academy = {
            intro = [[学术重地。售卖[malbatross_feather]、[trunk_summer]和[shark_fin]。
                    ----------------
                    这里是研究[townportaltalisman]等高阶科技的物资来源。]]
        },
        pig_shop_arcane = {
            intro = [[售卖魔法类道具。包括[icestaff]、[firestaff]和[nightsword]。
                    ----------------
                    同时也提供[blueamulet]和关键的[livinglog]。]]
        },
        pig_shop_weapons = {
            intro = [[售卖各种武装。包括[halberd]、[cutlass]和[blowdart_pipe]。
                    ----------------
                    [coconade]和各种[trap]也是这里的畅销货。]]
        },
        pig_shop_hatshop = {
            intro = [[服饰中心。售卖[tophat]、[beefalohat]以及稀有的[walrushat]。
                    ----------------
                    [sewing_kit]是每个绅士维持体面的必备品。]]
        },
        pig_shop_bank = {
            intro = [[货币中心。负责货币兑换，也售卖部分矿物。
                    ----------------
                    [pigman_banker]负责看管所有的财富。]]
        },
        pig_shop_tinker = {
            intro = [[蓝图商店。售卖各种稀有蓝图。]]
        },
        seaworthy = {
            name = "海洋之椅",
            intro = [[跨界航海定位装置。修复破损的海洋之椅需要 4 个[transistor]与 4 个[gears]。
                    ----------------
                    从零建造需要 4 个[nightmarefuel]、4 个[livinglog]、1 个[sunken_boat_trinket_4]、4 个[transistor]与 4 个[gears]。击败海妖后，其[krakenchest]内必定有 1 个[sunken_boat_trinket_4]。
                    ----------------
                    拆除破损的椅子返还 4 个[nightmarefuel]、4 个[livinglog]与 1 个[sunken_boat_trinket_4]，并返还已投入的升级材料；修复后拆除返还全部建造材料。
                    ----------------
                    坐在椅子上右键交互可激活航向定位菜单，在已知的海陆世界节点之间瞬间跃迁；传送过程仅消耗少量精神值（Sanity），带有屏幕渐变保护。]]
        },
        skyworthy = {
            name = "天空之椅",
            intro = [[跨界天空定位装置。修复破损的天空之椅需要 4 个[transistor]与 4 个[gears]。
                    ----------------
                    从零建造需要 4 个[nightmarefuel]、4 个[livinglog]、1 个[trinket_giftshop_4]、4 个[transistor]与 4 个[gears]。
                    ----------------
                    拆除破损的椅子返还 4 个[nightmarefuel]、4 个[livinglog]与 1 个[trinket_giftshop_4]，并返还已投入的升级材料；修复后拆除返还全部建造材料。
                    ----------------
                    坐在椅子上右键交互可激活传送菜单，在主大陆与哈姆雷特等已知世界节点之间瞬间跃迁；传送过程仅消耗少量精神值（Sanity），带有屏幕渐变保护。]]
        },
        sprinkler = {
            name = "喷灌机",
            intro = [[哈姆雷特农业灌溉设施。消耗燃料运作，持续向周围大范围喷洒清凉水雾。
                    ----------------
                    能够有效防止高温与干旱季节农作物枯萎，并能使已经枯萎的植物与作物迅速复苏返青。]]
        },
        volcano_altar = {
            name = "火山祭坛",
            intro = [[坐落于火山内部的古老贡品祭坛。
                    ----------------
                    在火山活跃季（旱季），向祭坛投入鸟蛋、[obsidian]、[monstermeat]等指定供品能够平息火山愤怒，延长平静期；若投掷未列入清单的杂物会激怒祭坛，立刻引发地壳震颤与落石惩罚。]]
        },
    },

    -- 生物类
    mobs = {
        firetwister = { intro = [[刷新在火山地区。是[twister]的火属性变种。]] },
        twister = { intro = [[哈姆雷特和海难地区的季节性威胁。]] },
        slipstor = { intro = [[丛林地区的奇特生物。]] },
        wildboreking = { intro = [[类似于[pigking]，可以换取金子，但具有攻击性。]] },
        ancient_herald = {
            name = "远古先驱",
            intro = [[毁灭季的恐怖天灾化身。
                    ----------------
                    不仅在毁灭季降临时作为世界BOSS频繁入侵，还在洞穴哈姆雷特遗迹入口的许愿井旁设有专属巢穴，固定每15天重新降临一次。
                    ----------------
                    击败后必定掉落[ARMORVORTEXCLOAK]（漩涡斗篷）的制作蓝图、暗影碎布与大量噩梦燃料。]]
        },
        pugalisk = {
            intro = [[在月圆时，会从[pugalisk_fountain]中生成。
                    ----------------
                    击杀会掉落[pugalisk_fountain]的蓝图。]]
        },
        kraken = {
            intro = [[深海巨兽。打开的第一个[messagebottle_sw]可以定位其巢穴。
                    ----------------
                    击败后生成的[krakenchest]内必定有 1 个[sunken_boat_trinket_4]，可用于从零建造海洋之椅。]]
        },

        pigman_mayor = {
            intro = [[管理者。收购[goldnugget]和[goldenbar]等金制品。]]
        },
        pigman_queen = {
            intro = [[最高统治者。对[pigcrownhat]、[pig_scepter]和[relic_4]非常感兴趣。]]
        },
        pigman_beautician = {
            intro = [[对羽毛有偏执的爱好。你可以把[peagawkfeather]和[feather_robin]卖给她。]]
        },
        pigman_florist = {
            intro = [[环保主义者。收购[petals]、[foliage]和[succulent_picked]。]]
        },
        pigman_erudite = {
            intro = [[神秘学者。专门收购[nightmarefuel]。]]
        },
        pigman_hatmaker = {
            intro = [[需要大量的[silk]来制作各种奇妙的帽子。]]
        },
        pigman_storeowner = {
            intro = [[勤俭持家。会收购你在城市修剪绿化得到的[clippings]。]]
        },
        pigman_banker = {
            intro = [[高端交易者。负责收购[redgem]、[bluegem]等各类昂贵宝石。]]
        },
        pigman_collector = {
            intro = [[喜欢收集各类[trinket_1]等玩具，以及[stinger]和[spidergland]。]]
        },
        pigman_hunter = {
            intro = [[勇猛的猎手。会收购[houndstooth]和[hippo_antler]。]]
        },
        pigman_professor = {
            intro = [[古物专家。你可以把在遗迹中挖到的[relic_1]等文物交给他。]]
        },
        pigman_usher = {
            intro = [[喜爱甜食。收购[honey]、[jammypreserves]和[waffles]。]]
        },
        pigman_farmer = {
            intro = [[基础资源收集者。收购[cutgrass]和[twigs]。]]
        },
        pigman_miner = {
            intro = [[矿石爱好者。通过卖给他[rocks]来赚取报酬。]]
        },
        pigman_mechanic = {
            intro = [[工程大师。收购加工过的[boards]、[cutstone]和[rope]。]]
        },
        pigman_royalguard = {
            intro = [[秩序维护者。可以使用[securitycontract]将其雇佣为保镖。]]
        },
        tigershark = {
            name = "虎鲨",
            intro = [[海难经典水陆两栖顶级掠食者。
                    ----------------
                    在季风季节会常驻在虎鲨巢穴哺育幼崽[sharkitten]；拥有水下潜泳突袭与陆地上跃猛扑双重战斗形态。
                    重生逻辑由世界系统统一管理；击败可获得大量生鱼肉、虎鲨皮与羽毛。]]
        },
        doydoy = {
            name = "渡渡鸟",
            intro = [[海难专属濒危珍稀鸟类。
                    ----------------
                    具备完整的雌雄性别遗传与配对繁衍系统；世界存活数量越少繁衍意愿越高，低于2只时濒临灭绝。
                    会随着时间筑巢产卵，蛋与羽毛拥有特殊用途；谨防食肉动物偷食渡渡鸟蛋。]]
        },
    },

    -- 道具类
    items = {
        ship = {
            name = "单人船",
            intro = [[单人船是按海难个人船逻辑深度重构的 DST 船只系统。
                    将船物品放置到水面后可以直接上船，船上的容器和装备槽通过船容器管理。
                    ----------------
                    【双槽位装备】：船尾槽位支持安装各类帆、铁旋桨与[trawlnet]；船头槽位支持安装[boatlantern]、[boatcannon]、[quackeringram]等武装与照明设备。
                    ----------------
                    【耐久与维修】：船体耐久接入独立 boathealth，支持修船套件、薇诺娜胶带与船坞精准维修；海浪冲击、碰撞均会消耗耐久。
                    ----------------
                    【安全保护】：重构了 sailor 与 sailable 交互逻辑，彻底修复重连与读档时掉入深海溺水的问题；下船后即刻清理存档记录，杜绝废船与刷物；支持海洋无缝环绕与[bermudatriangle]安全传送。]]
        },
        boat = {
            name = "船（多人）",
            intro = [[多人合作航行的载具。可以配合[保险杠]抵抗海浪冲击。
                    ----------------
                    联机版船：[boat]/[boat_pirate]/[boat_ancient]/[boatmetal] 分别能减轻海浪 30%/30%/40%/90% 的影响；
                    ----------------
                    保险杠：[BOAT_BUMPER_KELP]/[BOAT_BUMPER_SHELL]/[BOAT_BUMPER_YOTD]/[BOAT_BUMPER_CRABKING]分别能减轻安装方向 60%/80%/80%/100% 的影响。]]
        },
        trawlnet = {
            name = "拖网",
            intro = [[拖网是单人船的船尾核心捕捞装备。航行时会周期扫描船后方目标，并把捕获物直接存入拖网库存。
                    ----------------
                    【丰富渔获】：可以捕获水面漂浮物、热带海鱼、联机远洋鱼、深海鱼群、龙虾、水母、彩虹水母、海草根、公牛海带根、海黄瓜、贻贝农场等所有接入 trawlable 的目标。
                    ----------------
                    【负载平衡】：单次捕捞一件且有极短冷却；拖网内容物越多，船速减益越大（最高减速20%）；9格满载后自动脱落为可打开的[trawlnetdropped]浮水容器；跨界或卸载时具有安全重置保护。]]
        },
        smelter = {
            name = "炼钢炉",
            intro = [[用于熔炼[iron]，[goldnugget]或精炼矿石的高级设施。
                    可以通过[智能烹饪]模组查看炼金配方。]]
        },
        quackeringram = {
            name = "海妖撞锤",
            intro = [[单人船船头冲锋装备。由海妖喙角与齿轮制作而成。
                    ----------------
                    驾船冲撞海浪或敌对生物时造成巨额碰撞伤害与强力击退，撞击瞬间赋予驾船者短时速度提升，每次撞击消耗耐久。]]
        },
        boatcannon = {
            name = "船用大炮",
            intro = [[单人船船头重型火力装备。
                    ----------------
                    右键瞄准并向海面或敌人发射炮弹，造成大范围群伤爆轰；另有【黑曜石船炮】变种，命中附带高温灼烧与烈焰殉爆。]]
        },
        boatlantern = {
            name = "船灯",
            intro = [[单人船船头照明装备。
                    ----------------
                    安装后在黑夜与洞穴航行时提供大范围跟随光源，解放双手装备槽；可自由拆卸并添加可燃物补充燃料；另有基础版[boattorch]（船火把）。]]
        },
        sail = {
            name = "帆具",
            intro = [[单人船船尾核心动力装备。
                    ----------------
                    包括草帆、布帆、蛇皮帆、羽毛帆与[ironwind]（铁旋桨）等多种规格；显著提升单人船基础航速与顺风加速倍率，航行期间持续消耗耐久。]]
        },
        key_to_city = {
            name = "城市之钥",
            intro = [[哈姆雷特城市规划专属道具。
                    ----------------
                    在皇宫侧殿展柜换取，携带时赋予玩家城市建造者特权，可直接在室外规划建造猪人城镇各类商店、民房、街灯、守卫亭等公共市政建筑。]]
        },
        city_hammer = {
            name = "城市之锤",
            intro = [[市政工程拆迁工具。
                    ----------------
                    持有城市之钥特权时的专属拆迁工具，可用于安全拆除自行规划建造的城镇房屋与公共设施，并无损回收建筑材料。]]
        },
    },
}

local WikiTerms = {
    -- 词条
    type = "类型",
    recipe = "制作配方",
    unable_to_craft = "无法制作",
    friendly = "友好",
    hostile = "敌对",
    location = "出没地点",
    desc = "介绍",
    attitude = "归属阵营",
    unknown = "未知",
    about = "通告",
    generation = "机制",
    structures = "建筑",
    mobs = "生物",
    items = "道具",
    related = "相关物品",
    -----------
    mod_background = "制作背景",
    mod_progress = "更新日志",
    mod_about = "热带冒险 | 忒修斯之船",
    mod_preview = "写在前面",
    mod_sponser = "打赏支持我们！！",
    mod_sponser_list = "赞助名单",

    -- 提示
    click_to_read = "点击查看\"热带冒险\"百科",
    drag = "拖拽",
    reset = "重置",
    zoom = "缩放",
}

return {
    WikiDesc = WikiDesc,
    WikiTerms = WikiTerms,
}
