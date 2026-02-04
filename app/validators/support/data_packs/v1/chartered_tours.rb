# frozen_string_literal: true

# 全国热门城市包车游数据包 v1
# 包含74个热门旅游城市的包车游路线、景点数据
#
# 用途：
# - 初始化包车游系统的全国城市数据
# - 提供测试和演示数据
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 chartered_tours_all_cities_v1 数据包..."

# 定义74个热门旅游城市及其区域
CHARTER_CITIES = {
  # 直辖市
  '北京' => { region: '华北', pinyin: 'beijing', province: '北京', districts: ['东城区', '西城区', '朝阳区', '海淀区', '丰台区'] },
  '上海' => { region: '华东', pinyin: 'shanghai', province: '上海', districts: ['黄浦区', '浦东新区', '徐汇区', '静安区', '长宁区'] },
  '重庆' => { region: '西南', pinyin: 'chongqing', province: '重庆', districts: ['渝中区', '江北区', '南岸区', '渝北区', '九龙坡区'] },
  '天津' => { region: '华北', pinyin: 'tianjin', province: '天津', districts: ['和平区', '河西区', '南开区', '河北区', '河东区'] },
  
  # 国内热门城市
  '杭州' => { region: '华东', pinyin: 'hangzhou', province: '浙江', districts: ['西湖区', '上城区', '下城区', '拱墅区', '余杭区'] },
  '成都' => { region: '西南', pinyin: 'chengdu', province: '四川', districts: ['武侯区', '锦江区', '青羊区', '金牛区', '成华区'] },
  '西安' => { region: '西北', pinyin: 'xian', province: '陕西', districts: ['雁塔区', '碑林区', '莲湖区', '新城区', '未央区'] },
  '南京' => { region: '华东', pinyin: 'nanjing', province: '江苏', districts: ['玄武区', '秦淮区', '建邺区', '鼓楼区', '栖霞区'] },
  '武汉' => { region: '华中', pinyin: 'wuhan', province: '湖北', districts: ['武昌区', '汉口区', '汉阳区', '洪山区', '青山区'] },
  '苏州' => { region: '华东', pinyin: 'suzhou', province: '江苏', districts: ['姑苏区', '工业园区', '虎丘区', '吴中区', '相城区'] },
  '大连' => { region: '东北', pinyin: 'dalian', province: '辽宁', districts: ['中山区', '西岗区', '沙河口区', '甘井子区', '旅顺口区'] },
  '厦门' => { region: '华东', pinyin: 'xiamen', province: '福建', districts: ['思明区', '湖里区', '集美区', '海沧区', '同安区'] },
  '深圳' => { region: '华南', pinyin: 'shenzhen', province: '广东', districts: ['福田区', '罗湖区', '南山区', '宝安区', '龙岗区'] },
  '广州' => { region: '华南', pinyin: 'guangzhou', province: '广东', districts: ['天河区', '越秀区', '海珠区', '荔湾区', '白云区'] },
  '珠海' => { region: '华南', pinyin: 'zhuhai', province: '广东', districts: ['香洲区', '斗门区', '金湾区'] },
  '三亚' => { region: '华南', pinyin: 'sanya', province: '海南', districts: ['天涯区', '吉阳区', '海棠区', '崖州区'] },
  '丽江' => { region: '西南', pinyin: 'lijiang', province: '云南', districts: ['古城区', '玉龙纳西族自治县', '永胜县', '华坪县', '宁蒗彝族自治县'] },
  '桂林' => { region: '华南', pinyin: 'guilin', province: '广西', districts: ['秀峰区', '叠彩区', '象山区', '七星区', '雁山区'] },
  '青岛' => { region: '华东', pinyin: 'qingdao', province: '山东', districts: ['市南区', '市北区', '李沧区', '崂山区', '黄岛区'] },
  '济南' => { region: '华东', pinyin: 'jinan', province: '山东', districts: ['历下区', '市中区', '槐荫区', '天桥区', '历城区'] },
  '烟台' => { region: '华东', pinyin: 'yantai', province: '山东', districts: ['芝罘区', '福山区', '牟平区', '莱山区', '开发区'] },
  '长沙' => { region: '华中', pinyin: 'changsha', province: '湖南', districts: ['岳麓区', '芙蓉区', '天心区', '开福区', '雨花区'] },
  '哈尔滨' => { region: '东北', pinyin: 'haerbin', province: '黑龙江', districts: ['道里区', '南岗区', '道外区', '香坊区', '平房区'] },
  '长春' => { region: '东北', pinyin: 'changchun', province: '吉林', districts: ['南关区', '朝阳区', '绿园区', '二道区', '宽城区'] },
  '沈阳' => { region: '东北', pinyin: 'shenyang', province: '辽宁', districts: ['沈河区', '和平区', '大东区', '皇姑区', '铁西区'] },
  '大同' => { region: '华北', pinyin: 'datong', province: '山西', districts: ['平城区', '云冈区', '云州区', '新荣区'] },
  '洛阳' => { region: '华中', pinyin: 'luoyang', province: '河南', districts: ['老城区', '西工区', '瀍河区', '涧西区', '洛龙区'] },
  '郑州' => { region: '华中', pinyin: 'zhengzhou', province: '河南', districts: ['中原区', '二七区', '管城区', '金水区', '上街区'] },
  '合肥' => { region: '华东', pinyin: 'hefei', province: '安徽', districts: ['庐阳区', '瑶海区', '蜀山区', '包河区', '经开区'] },
  '南昌' => { region: '华东', pinyin: 'nanchang', province: '江西', districts: ['东湖区', '西湖区', '青云谱区', '青山湖区', '新建区'] },
  '福州' => { region: '华东', pinyin: 'fuzhou', province: '福建', districts: ['鼓楼区', '台江区', '仓山区', '晋安区', '马尾区'] },
  '昆明' => { region: '西南', pinyin: 'kunming', province: '云南', districts: ['五华区', '盘龙区', '官渡区', '西山区', '呈贡区'] },
  '贵阳' => { region: '西南', pinyin: 'guiyang', province: '贵州', districts: ['南明区', '云岩区', '花溪区', '乌当区', '白云区'] },
  '兰州' => { region: '西北', pinyin: 'lanzhou', province: '甘肃', districts: ['城关区', '七里河区', '西固区', '安宁区', '红古区'] },
  '乌鲁木齐' => { region: '西北', pinyin: 'wulumuqi', province: '新疆', districts: ['天山区', '沙依巴克区', '新市区', '水磨沟区', '头屯河区'] },
  '吐鲁番' => { region: '西北', pinyin: 'tulufan', province: '新疆', districts: ['高昌区', '鄯善县', '托克逊县'] },
  '拉萨' => { region: '西南', pinyin: 'lasa', province: '西藏', districts: ['城关区', '堆龙德庆区', '达孜区', '林周县', '当雄县'] },
  '西宁' => { region: '西北', pinyin: 'xining', province: '青海', districts: ['城东区', '城中区', '城西区', '城北区', '湟中区'] },
  '东莞' => { region: '华南', pinyin: 'dongguan', province: '广东', districts: ['南城区', '东城区', '莞城区', '万江区', '石龙镇'] },
  '佛山' => { region: '华南', pinyin: 'foshan', province: '广东', districts: ['禅城区', '南海区', '顺德区', '三水区', '高明区'] },
  '中山' => { region: '华南', pinyin: 'zhongshan', province: '广东', districts: ['石岐区', '东区', '西区', '南区', '五桂山区'] },
  '惠州' => { region: '华南', pinyin: 'huizhou', province: '广东', districts: ['惠城区', '惠阳区', '博罗县', '惠东县', '龙门县'] },
  '南宁' => { region: '华南', pinyin: 'nanning', province: '广西', districts: ['青秀区', '兴宁区', '江南区', '西乡塘区', '良庆区'] },
  '香港' => { region: '港澳台', pinyin: 'xianggang', province: '香港', districts: ['中西区', '湾仔区', '东区', '南区', '油尖旺区'] },
  '澳门' => { region: '港澳台', pinyin: 'aomen', province: '澳门', districts: ['澳门半岛', '氹仔', '路环'] },
  
  # 国际热门城市 (东亚)
  '东京' => { region: '日本', pinyin: 'dongjing', province: '日本', districts: ['千代田区', '港区', '新宿区', '涩谷区', '台东区'] },
  '大阪' => { region: '日本', pinyin: 'daban', province: '日本', districts: ['北区', '中央区', '西区', '浪速区', '天王寺区'] },
  '京都' => { region: '日本', pinyin: 'jingdu', province: '日本', districts: ['东山区', '下京区', '中京区', '上京区', '左京区'] },
  '冲绳' => { region: '日本', pinyin: 'chongsheng', province: '日本', districts: ['那霸市', '宜野湾市', '浦添市', '名护市', '丰见城市'] },
  '札幌' => { region: '日本', pinyin: 'zhafang', province: '日本', districts: ['中央区', '北区', '东区', '白石区', '厚别区'] },
  '福冈' => { region: '日本', pinyin: 'fugang', province: '日本', districts: ['博多区', '中央区', '南区', '城南区', '早良区'] },
  '首尔' => { region: '韩国', pinyin: 'shouer', province: '韩国', districts: ['江南区', '钟路区', '中区', '龙山区', '麻浦区'] },
  '釜山' => { region: '韩国', pinyin: 'fushan', province: '韩国', districts: ['海云台区', '釜山镇区', '东莱区', '南区', '北区'] },
  '济州' => { region: '韩国', pinyin: 'jizhou', province: '韩国', districts: ['济州市', '西归浦市'] },
  
  # 国际热门城市 (东南亚)
  '曼谷' => { region: '泰国', pinyin: 'mangu', province: '泰国', districts: ['Sukhumvit', 'Silom', 'Siam', 'Pratunam', 'Chinatown'] },
  '普吉' => { region: '泰国', pinyin: 'puji', province: '泰国', districts: ['Patong', 'Kata', 'Karon', 'Phuket Town', 'Kamala'] },
  '清迈' => { region: '泰国', pinyin: 'qingmai', province: '泰国', districts: ['Old City', 'Nimman', 'Riverside', 'Night Bazaar', 'Hang Dong'] },
  '芭提雅' => { region: '泰国', pinyin: 'batiya', province: '泰国', districts: ['Central Pattaya', 'North Pattaya', 'South Pattaya', 'Jomtien', 'Naklua'] },
  '新加坡' => { region: '新加坡', pinyin: 'xinjiapo', province: '新加坡', districts: ['Marina Bay', 'Orchard', 'Chinatown', 'Little India', 'Sentosa'] },
  '吉隆坡' => { region: '马来西亚', pinyin: 'jilongpo', province: '马来西亚', districts: ['KLCC', 'Bukit Bintang', 'Chinatown', 'Brickfields', 'Bangsar'] },
  '槟城' => { region: '马来西亚', pinyin: 'bincheng', province: '马来西亚', districts: ['Georgetown', 'Batu Ferringhi', 'Tanjung Bungah', 'Gurney Drive', 'Penang Hill'] },
  '河内' => { region: '越南', pinyin: 'henei', province: '越南', districts: ['Hoan Kiem', 'Ba Dinh', 'Dong Da', 'Tay Ho', 'Cau Giay'] },
  '胡志明' => { region: '越南', pinyin: 'huzhiming', province: '越南', districts: ['District 1', 'District 3', 'District 5', 'Binh Thanh', 'Phu Nhuan'] },
  '芽庄' => { region: '越南', pinyin: 'yazhuang', province: '越南', districts: ['Nha Trang Center', 'Vinpearl', 'Cam Ranh', 'Ninh Hoa', 'Bai Dai'] },
  
  # 国际热门城市 (欧洲)
  '巴黎' => { region: '法国', pinyin: 'bali', province: '法国', districts: ['1区', '7区', '8区', '16区', '18区'] },
  '伦敦' => { region: '英国', pinyin: 'lundun', province: '英国', districts: ['Westminster', 'Camden', 'Kensington', 'Tower Hamlets', 'Southwark'] },
  '罗马' => { region: '意大利', pinyin: 'luoma', province: '意大利', districts: ['Centro Storico', 'Trastevere', 'Monti', 'Prati', 'Testaccio'] },
  '巴塞罗那' => { region: '西班牙', pinyin: 'baseluona', province: '西班牙', districts: ['Gothic Quarter', 'Eixample', 'Gracia', 'Barceloneta', 'Sant Marti'] },
  '阿姆斯特丹' => { region: '荷兰', pinyin: 'amusitedan', province: '荷兰', districts: ['Centrum', 'Zuid', 'West', 'Oost', 'Noord'] },
  '慕尼黑' => { region: '德国', pinyin: 'munihei', province: '德国', districts: ['Altstadt', 'Schwabing', 'Haidhausen', 'Neuhausen', 'Laim'] },
  
  # 国际热门城市 (北美)
  '纽约' => { region: '美国', pinyin: 'niuyue', province: '美国', districts: ['Manhattan', 'Brooklyn', 'Queens', 'Bronx', 'Staten Island'] },
  '洛杉矶' => { region: '美国', pinyin: 'luoshanji', province: '美国', districts: ['Downtown', 'Hollywood', 'Beverly Hills', 'Santa Monica', 'Venice'] },
  '旧金山' => { region: '美国', pinyin: 'jiujinshan', province: '美国', districts: ['Downtown', 'Fisherman\'s Wharf', 'Mission', 'Castro', 'Haight-Ashbury'] },
  '拉斯维加斯' => { region: '美国', pinyin: 'lasiweijiasi', province: '美国', districts: ['Strip', 'Downtown', 'Henderson', 'Summerlin', 'North Las Vegas'] },
  '温哥华' => { region: '加拿大', pinyin: 'wengehua', province: '加拿大', districts: ['Downtown', 'West End', 'Gastown', 'Yaletown', 'Kitsilano'] },
  '多伦多' => { region: '加拿大', pinyin: 'duolunduo', province: '加拿大', districts: ['Downtown', 'Yorkville', 'Distillery', 'Queen West', 'Harbourfront'] },
  '蒙特利尔' => { region: '加拿大', pinyin: 'mengteli\'er', province: '加拿大', districts: ['Old Montreal', 'Downtown', 'Plateau', 'Mile End', 'Westmount'] },
  
  # 国际热门城市 (大洋洲)
  '悉尼' => { region: '澳大利亚', pinyin: 'xini', province: '澳大利亚', districts: ['CBD', 'The Rocks', 'Darling Harbour', 'Bondi', 'Manly'] },
  '墨尔本' => { region: '澳大利亚', pinyin: 'moerben', province: '澳大利亚', districts: ['CBD', 'Southbank', 'St Kilda', 'Fitzroy', 'Carlton'] },
  '黄金海岸' => { region: '澳大利亚', pinyin: 'huangjinhaian', province: '澳大利亚', districts: ['Surfers Paradise', 'Broadbeach', 'Burleigh Heads', 'Main Beach', 'Coolangatta'] },
  '奥克兰' => { region: '新西兰', pinyin: 'aokela<br>', province: '新西兰', districts: ['CBD', 'Viaduct', 'Ponsonby', 'Parnell', 'Mission Bay'] },
  
  # 国际热门城市 (中东)
  '迪拜' => { region: '阿联酋', pinyin: 'dibai', province: '阿联酋', districts: ['Downtown', 'Marina', 'JBR', 'Deira', 'Bur Dubai'] },
  
  # 国际热门城市 (其他)
  '伊斯坦布尔' => { region: '土耳其', pinyin: 'yisitanbuer', province: '土耳其', districts: ['Sultanahmet', 'Beyoglu', 'Besiktas', 'Kadikoy', 'Uskudar'] },
  '开罗' => { region: '埃及', pinyin: 'kailuo', province: '埃及', districts: ['Downtown', 'Islamic Cairo', 'Zamalek', 'Heliopolis', 'Giza'] }
}.freeze

# 城市景点模板 - 根据城市特色生成不同景点
def generate_attractions_for_city(city_name, city_info)
  base_attractions = case city_name
  when '北京'
    ['故宫', '长城', '天坛', '颐和园', '圆明园', '天安门', '王府井', '南锣鼓巷', '798艺术区']
  when '上海'
    ['外滩', '东方明珠', '豫园', '南京路步行街', '田子坊', '城隍庙', '朱家角', '新天地', '迪士尼']
  when '重庆'
    ['洪崖洞', '解放碑', '磁器口', '长江索道', '朝天门', '武隆天坑', '南山一棵树', '大足石刻', '渣滓洞']
  when '天津'
    ['天津之眼', '意式风情街', '五大道', '古文化街', '南开大学', '盘山', '海河', '瓷房子', '津湾广场']
  when '杭州'
    ['西湖', '灵隐寺', '雷峰塔', '西溪湿地', '千岛湖', '宋城', '河坊街', '断桥', '三潭印月']
  when '成都'
    ['大熊猫基地', '宽窄巷子', '锦里', '武侯祠', '杜甫草堂', '青城山', '都江堰', '春熙路', '文殊院']
  when '西安'
    ['兵马俑', '大雁塔', '古城墙', '华清池', '回民街', '大唐芙蓉园', '陕西历史博物馆', '华山', '钟楼']
  when '南京'
    ['中山陵', '夫子庙', '总统府', '玄武湖', '明城墙', '牛首山', '栖霞山', '秦淮河', '雨花台']
  when '武汉'
    ['黄鹤楼', '武汉大学', '湖北省博物馆', '东湖听涛景区', '长江游船', '古德寺', '晴川阁', '户部巷', '木兰天池']
  when '苏州'
    ['拙政园', '虎丘', '留园', '寒山寺', '平江路', '金鸡湖', '周庄', '同里', '狮子林']
  when '大连'
    ['星海广场', '老虎滩', '棒棰岛', '金石滩', '发现王国', '俄罗斯风情街', '渔人码头', '圣亚海洋世界', '滨海路']
  when '厦门'
    ['鼓浪屿', '南普陀寺', '环岛路', '曾厝垵', '中山路', '厦门大学', '胡里山炮台', '日光岩', '集美学村']
  when '深圳'
    ['世界之窗', '欢乐谷', '东部华侨城', '深圳湾公园', '大梅沙', '莲花山公园', '华强北', '大鹏所城', '红树林']
  when '广州'
    ['广州塔', '长隆野生动物园', '陈家祠', '沙面', '上下九', '白云山', '珠江夜游', '越秀公园', '南越王墓']
  when '珠海'
    ['长隆海洋王国', '情侣路', '珠海渔女', '东澳岛', '外伶仃岛', '圆明新园', '梦幻水城', '珠海大剧院', '海滨公园']
  when '三亚'
    ['亚龙湾', '天涯海角', '南山寺', '蜈支洲岛', '大东海', '呀诺达', '鹿回头', '千古情', '亚特兰蒂斯']
  when '丽江'
    ['丽江古城', '玉龙雪山', '泸沽湖', '束河古镇', '虎跳峡', '拉市海', '黑龙潭', '白沙古镇', '观音峡']
  when '桂林'
    ['漓江', '象鼻山', '两江四湖', '龙脊梯田', '阳朔西街', '银子岩', '遇龙河', '十里画廊', '印象刘三姐']
  when '青岛'
    ['栈桥', '八大关', '崂山', '五四广场', '啤酒博物馆', '小鱼山', '金沙滩', '极地海洋世界', '信号山']
  when '济南'
    ['趵突泉', '大明湖', '千佛山', '泉城广场', '黑虎泉', '芙蓉街', '五龙潭', '灵岩寺', '红叶谷']
  when '烟台'
    ['蓬莱阁', '长岛', '养马岛', '金沙滩', '张裕酒庄', '月亮湾', '烟台山', '昆嵛山', '海昌鲸鲨馆']
  when '长沙'
    ['橘子洲', '岳麓山', '岳麓书院', '太平街', '坡子街', '长沙博物馆', '天心阁', '靖港古镇', '世界之窗']
  when '哈尔滨'
    ['中央大街', '圣索菲亚教堂', '太阳岛', '冰雪大世界', '松花江', '虎林园', '果戈里大街', '伏尔加庄园', '极地馆']
  when '长春'
    ['伪满皇宫', '南湖公园', '净月潭', '长影世纪城', '世界雕塑园', '长春动植物园', '桂林路', '红旗街', '东北虎园']
  when '沈阳'
    ['故宫', '北陵公园', '中街', '棋盘山', '九一八纪念馆', '张氏帅府', '太原街', '方特欢乐世界', '沈阳植物园']
  when '大同'
    ['云冈石窟', '悬空寺', '华严寺', '恒山', '古城墙', '九龙壁', '善化寺', '大同火山群', '法华寺']
  when '洛阳'
    ['龙门石窟', '白马寺', '洛阳古城', '关林', '白云山', '老君山', '丽景门', '王城公园', '隋唐遗址']
  when '郑州'
    ['少林寺', '黄河风景区', '嵩山', '二七塔', '河南博物院', '方特梦幻王国', '郑东新区', '绿博园', '北宋皇陵']
  when '合肥'
    ['包公祠', '三国遗址公园', '逍遥津', '李鸿章故居', '天鹅湖', '滨湖湿地', '大蜀山', '罍街', '徽园']
  when '南昌'
    ['滕王阁', '八一广场', '秋水广场', '绳金塔', '南昌之星', '梅岭', '青山湖', '八大山人', '万寿宫']
  when '福州'
    ['三坊七巷', '鼓山', '西湖公园', '福道', '罗星塔', '马尾船政', '林则徐纪念馆', '闽江夜游', '平潭岛']
  when '昆明'
    ['滇池', '石林', '翠湖', '西山', '民族村', '金马碧鸡坊', '官渡古镇', '九乡', '东川红土地']
  when '贵阳'
    ['黄果树瀑布', '青岩古镇', '甲秀楼', '花溪公园', '天河潭', '南江大峡谷', '红枫湖', '黔灵山', '文昌阁']
  when '兰州'
    ['黄河母亲', '中山桥', '白塔山', '甘肃博物馆', '五泉山', '水车园', '正宁路夜市', '兴隆山', '吐鲁沟']
  when '乌鲁木齐'
    ['天山天池', '国际大巴扎', '红山公园', '新疆博物馆', '南山牧场', '天山大峡谷', '水磨沟', '植物园', '野马古生态园']
  when '吐鲁番'
    ['火焰山', '葡萄沟', '坎儿井', '高昌古城', '交河故城', '柏孜克里克千佛洞', '苏公塔', '艾丁湖', '吐峪沟']
  when '拉萨'
    ['布达拉宫', '大昭寺', '八廓街', '罗布林卡', '色拉寺', '哲蚌寺', '纳木错', '羊卓雍错', '扎基寺']
  when '西宁'
    ['塔尔寺', '青海湖', '茶卡盐湖', '东关清真寺', '南山公园', '北山寺', '莫家街', '坎布拉', '日月山']
  when '东莞'
    ['可园', '虎门炮台', '鸦片战争博物馆', '松山湖', '观音山', '隐贤山庄', '威远炮台', '海战博物馆', '粤晖园']
  when '佛山'
    ['祖庙', '清晖园', '西樵山', '南风古灶', '梁园', '佛山创意产业园', '长鹿农庄', '顺德美食', '岭南天地']
  when '中山'
    ['孙中山故居', '中山纪念堂', '紫马岭公园', '岐江公园', '金钟湖', '詹园', '中山影视城', '石岐乳鸽', '逍遥谷']
  when '惠州'
    ['西湖', '巽寮湾', '罗浮山', '双月湾', '红花湖', '惠州古城', '南昆山', '大亚湾', '博罗']
  when '南宁'
    ['青秀山', '南湖公园', '民族大道', '中山路', '广西博物馆', '邕江夜游', '大明山', '德天瀑布', '青秀万达']
  when '香港'
    ['维多利亚港', '太平山顶', '迪士尼乐园', '海洋公园', '尖沙咀', '中环', '铜锣湾', '大屿山', '旺角']
  when '澳门'
    ['大三巴', '威尼斯人', '渔人码头', '澳门塔', '妈阁庙', '葡京娱乐场', '黑沙海滩', '龙环葡韵', '议事亭前地']
  when '东京'
    ['浅草寺', '晴空塔', '东京塔', '明治神宫', '涩谷', '新宿御苑', '银座', '上野公园', '迪士尼乐园']
  when '大阪'
    ['大阪城', '道顿堀', '心斋桥', '环球影城', '天守阁', '通天阁', '梅田蓝天大厦', '黑门市场', '四天王寺']
  when '京都'
    ['清水寺', '金阁寺', '伏见稻荷', '岚山', '二条城', '八坂神社', '祗园', '平安神宫', '银阁寺']
  when '冲绳'
    ['首里城', '美丽海水族馆', '国际通', '万座毛', '古宇利岛', '残波岬', '美国村', '玉泉洞', '识名园']
  when '札幌'
    ['大通公园', '札幌电视塔', '白色恋人公园', '北海道大学', '羊之丘', '藻岩山', '时计台', '狸小路', '圆山公园']
  when '福冈'
    ['太宰府', '福冈塔', '博多运河城', '天神地下街', '福冈城', '大濠公园', '中洲屋台', '海之中道', '栉田神社']
  when '首尔'
    ['景福宫', '明洞', '南山塔', '梨大', '弘大', '北村韩屋村', '汉江游船', '乐天世界', '清溪川']
  when '釜山'
    ['海云台', '甘川文化村', '广安大桥', '札嘎其市场', '太宗台', '龙头山公园', '梵鱼寺', '海东龙宫寺', '新世界百货']
  when '济州'
    ['汉拿山', '城山日出峰', '涉地可支', '泰迪熊博物馆', '牛岛', '山君不离', '正房瀑布', '龙头岩', '挟才海水浴场']
  when '曼谷'
    ['大皇宫', '玉佛寺', '卧佛寺', '四面佛', '暹罗广场', '湄南河', '考山路', 'Terminal 21', 'Asiatique']
  when '普吉'
    ['芭东海滩', '卡伦海滩', '卡塔海滩', '皮皮岛', '查龙寺', '普吉镇', '幻多奇乐园', '拉威海滩', 'Big Buddha']
  when '清迈'
    ['双龙寺', '宁曼路', '古城', '夜市', '大象自然公园', '素贴山', '清迈大学', 'Maya商场', '周日夜市']
  when '芭提雅'
    ['芭提雅海滩', '真理寺', '东芭乐园', 'Walking Street', '四方水上市场', '信不信由你博物馆', 'Big Buddha Hill', '蒂芬妮人妖秀', '珊瑚岛']
  when '新加坡'
    ['滨海湾金沙', '鱼尾狮公园', '圣淘沙', '乌节路', '牛车水', '小印度', '克拉码头', '环球影城', '滨海湾花园']
  when '吉隆坡'
    ['双子塔', '独立广场', '茨厂街', '中央艺术坊', '云顶高原', '黑风洞', '国家清真寺', '阿罗街', 'Pavilion']
  when '槟城'
    ['乔治城', '升旗山', '极乐寺', '姓氏桥', '槟城博物馆', '爱情巷', '峇都丁宜', 'Gurney Plaza', '壁画街']
  when '河内'
    ['还剑湖', '巴亭广场', '三十六行街', '河内大教堂', '文庙', '胡志明陵', '西湖', '龙边桥', '河内歌剧院']
  when '胡志明'
    ['统一宫', '红教堂', '中央邮局', '滨城市场', '范五老街', '战争博物馆', '湄公河三角洲', '咖啡公寓', '阮惠步行街']
  when '芽庄'
    ['芽庄海滩', '珍珠岛', '婆那加占婆塔', '芽庄大教堂', '钟屿石岬角', '泥浴中心', '龙山寺', 'I-Resort', '芽庄海洋馆']
  when '巴黎'
    ['埃菲尔铁塔', '卢浮宫', '凯旋门', '塞纳河游船', '蒙马特高地', '圣母院', '香榭丽舍大街', '奥赛博物馆', '凡尔赛宫']
  when '伦敦'
    ['大本钟', '伦敦眼', '白金汉宫', '大英博物馆', '塔桥', '伦敦塔', '剑桥', '牛津街', '哈利波特片场']
  when '罗马'
    ['斗兽场', '梵蒂冈', '许愿池', '西班牙广场', '万神殿', '圣彼得大教堂', '真理之口', '威尼斯广场', '纳沃纳广场']
  when '巴塞罗那'
    ['圣家堂', '米拉之家', '古埃尔公园', '巴特罗之家', '哥特区', '兰布拉大道', '蒙锥克山', '诺坎普', '海滩']
  when '阿姆斯特丹'
    ['运河游船', '梵高博物馆', '安妮之家', '红灯区', '水坝广场', '国立博物馆', '库肯霍夫', '桑斯安斯风车村', '阿姆斯特丹王宫']
  when '慕尼黑'
    ['玛丽恩广场', '新天鹅堡', '慕尼黑王宫', '英国花园', '宝马博物馆', '慕尼黑奥林匹克公园', 'Hofbräuhaus', '德意志博物馆', '宁芬堡宫']
  when '纽约'
    ['自由女神像', '时代广场', '中央公园', '帝国大厦', '布鲁克林大桥', '大都会博物馆', '华尔街', '第五大道', '洛克菲勒中心']
  when '洛杉矶'
    ['好莱坞星光大道', '环球影城', '圣莫尼卡', '格里菲斯天文台', '盖蒂中心', '威尼斯海滩', '比佛利山庄', '迪士尼乐园', '圣塔芭芭拉']
  when '旧金山'
    ['金门大桥', '渔人码头', '九曲花街', 'Alcatraz岛', '双子峰', '金银岛', '联合广场', '唐人街', '硅谷']
  when '拉斯维加斯'
    ['赌城大道', '百乐宫喷泉', '大峡谷', '红岩峡谷', '胡佛大坝', '威尼斯人酒店', '弗里蒙街', 'High Roller摩天轮', 'Stratosphere']
  when '温哥华'
    ['斯坦利公园', '格兰维尔岛', 'Canada Place', '煤气镇', '卡皮拉诺吊桥', '惠斯勒', '维多利亚', 'Granville Island', '狮门大桥']
  when '多伦多'
    ['CN塔', '多伦多群岛', '安大略湖', '圣劳伦斯市场', '古酿酒厂区', 'Yorkville', '尼亚加拉瀑布', 'Casa Loma', '皇家安大略博物馆']
  when '蒙特利尔'
    ['老蒙特利尔', '圣母大教堂', '蒙特利尔港', '皇家山公园', '生物圈', '地下城', '圣约瑟夫礼拜堂', 'Mont-Royal', '麦吉尔大学']
  when '悉尼'
    ['歌剧院', '海港大桥', '邦迪海滩', 'Darling Harbour', '岩石区', '蓝山国家公园', '悉尼塔', '皇家植物园', 'Taronga Zoo']
  when '墨尔本'
    ['联邦广场', '涂鸦巷', 'St Kilda海滩', '大洋路', '维多利亚女王市场', '皇家植物园', 'Eureka Tower', '墨尔本博物馆', '菲利普岛']
  when '黄金海岸'
    ['Surfers Paradise', '华纳兄弟电影世界', '海洋世界', '梦幻世界', 'Currumbin野生动物园', '春溪国家公园', 'Broadbeach', 'Q1大厦', '天堂农庄']
  when '奥克兰'
    ['天空塔', '使命湾', '怀赫科岛', 'One Tree Hill', '海事博物馆', 'Viaduct Harbour', '伊甸山', '奥克兰动物园', '皇后街']
  when '迪拜'
    ['哈利法塔', '迪拜购物中心', '棕榈岛', '帆船酒店', '黄金市场', '迪拜之眼', '朱美拉海滩', '迪拜喷泉', 'IMG冒险世界']
  when '伊斯坦布尔'
    ['蓝色清真寺', '圣索菲亚大教堂', '托普卡帕宫', '大巴扎', '加拉太塔', '博斯普鲁斯海峡', '多尔玛巴赫切宫', '地下水宫', '苏丹阿赫迈特广场']
  when '开罗'
    ['金字塔', '狮身人面像', '埃及博物馆', '萨拉丁城堡', '汗哈利利市场', '爱资哈尔清真寺', '尼罗河游船', '科普特区', '伊本图伦清真寺']
  else
    ["#{city_name}中心", "#{city_name}博物馆", "#{city_name}公园", "#{city_name}古城", "#{city_name}广场"]
  end
  
  attractions_data = []
  base_attractions.each_with_index do |attr_name, idx|
    district = city_info[:districts][idx % city_info[:districts].size]
    attractions_data << {
      name: attr_name,
      city: city_name,
      province: city_info[:province],
      district: district,
      address: "#{district}#{attr_name}",
      cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
      latitude: 30.0 + rand * 20,
      longitude: 100.0 + rand * 30,
      rating: (4.0 + rand * 1.0).round(1),
      review_count: (1000 + rand(20000)).to_i,
      opening_hours: ['08:00-18:00', '09:00-17:00', '全天开放', '08:30-17:30'].sample,
      phone: "#{['020', '021', '010', '027', '028', '029'].sample}-#{rand(80000000..89999999)}",
      description: "#{city_name}著名景点#{attr_name}，#{['历史悠久', '风景秀丽', '文化深厚', '独具特色', '游客必游'].sample}。",
      data_version: '0'
    }
  end
  
  attractions_data
end

# 生成包车路线
def generate_routes_for_city(city_name, city_id)
  routes_data = [
    {
      name: "#{city_name}经典一日游",
      city_id: city_id,
      duration_days: 1,
      distance_km: 50,
      category: 'hot',
      description: "游览#{city_name}最著名的景点，深度体验#{city_name}历史文化。",
      price_from: (380.0 + rand(100)).round(0),
      highlights: ["#{city_name}地标", '历史文化', '美食体验', '深度游览', '专业导游'].to_json,
      cover_image_url: ImageSeedHelper.random_image_from_category(:tours),
      data_version: '0'
    },
    {
      name: "#{city_name}精华四景",
      city_id: city_id,
      duration_days: 1,
      distance_km: 40,
      category: 'featured',
      description: "精选#{city_name}四大必游景点，轻松舒适的行程安排。",
      price_from: (350.0 + rand(100)).round(0),
      highlights: ["#{city_name}必游", '经典路线', '舒适行程', '性价比高'].to_json,
      cover_image_url: ImageSeedHelper.random_image_from_category(:tours),
      data_version: '0'
    },
    {
      name: "#{city_name}文化深度游",
      city_id: city_id,
      duration_days: 1,
      distance_km: 55,
      category: 'classic',
      description: "深度探索#{city_name}历史文化，感受深厚的历史底蕴。",
      price_from: (450.0 + rand(100)).round(0),
      highlights: ['历史遗迹', '文化体验', '深度讲解', '博物馆参观'].to_json,
      cover_image_url: ImageSeedHelper.random_image_from_category(:tours),
      data_version: '0'
    }
  ]
  
  routes_data
end

# 车型数据只需创建一次（全国通用）
vehicle_types_data = [
  {
    name: '经济5座',
    category: '5座',
    level: '经济',
    seats: 5,
    luggage_capacity: 2,
    hourly_price_6h: 308.0,
    hourly_price_8h: 388.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  },
  {
    name: '舒适5座',
    category: '5座',
    level: '舒适',
    seats: 5,
    luggage_capacity: 2,
    hourly_price_6h: 378.0,
    hourly_price_8h: 478.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  },
  {
    name: '豪华5座',
    category: '5座',
    level: '豪华',
    seats: 5,
    luggage_capacity: 3,
    hourly_price_6h: 588.0,
    hourly_price_8h: 688.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  },
  {
    name: '经济7座',
    category: '7座',
    level: '经济',
    seats: 7,
    luggage_capacity: 3,
    hourly_price_6h: 428.0,
    hourly_price_8h: 528.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  },
  {
    name: '舒适7座',
    category: '7座',
    level: '舒适',
    seats: 7,
    luggage_capacity: 3,
    hourly_price_6h: 528.0,
    hourly_price_8h: 628.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  },
  {
    name: '商务巴士',
    category: '巴士',
    level: '舒适',
    seats: 15,
    luggage_capacity: 10,
    hourly_price_6h: 888.0,
    hourly_price_8h: 1088.0,
    included_mileage: 100,
    image_url: ImageSeedHelper.random_image_from_category(:cars),
    data_version: '0'
  }
]

# 检查并创建车型数据（仅一次）
if VehicleType.where(data_version: '0').count == 0
  VehicleType.insert_all(vehicle_types_data)
  puts "✓ 创建车型数据: #{vehicle_types_data.size}种"
end

# 为每个城市生成数据
total_attractions = 0
total_routes = 0
total_route_attractions = 0

CHARTER_CITIES.each do |city_name, city_info|
  puts "正在处理城市: #{city_name} (#{city_info[:region]})..."
  
  # 1. 确保城市存在
  city = City.find_or_create_by!(name: city_name) do |c|
    c.pinyin = city_info[:pinyin]
    c.region = city_info[:region]
    c.is_hot = true
    c.data_version = '0'
  end
  
  # 2. 创建景点
  attractions_data = generate_attractions_for_city(city_name, city_info)
  Attraction.insert_all(attractions_data)
  
  # 为新插入的 Attraction 生成 slug（FriendlyId 需要 save 触发回调）
  Attraction.where(city: city_name, data_version: '0', slug: [nil, '']).find_each(&:save)
  
  attractions = Attraction.where(city: city_name, data_version: '0').index_by(&:name)
  total_attractions += attractions.size
  
  # 3. 创建包车路线
  routes_data = generate_routes_for_city(city_name, city.id)
  CharterRoute.insert_all(routes_data)
  
  # 为新插入的 CharterRoute 生成 slug（FriendlyId 需要 save 触发回调）
  CharterRoute.where(city_id: city.id, slug: [nil, '']).find_each(&:save)
  
  routes = CharterRoute.where(city_id: city.id, data_version: '0').index_by(&:name)
  total_routes += routes.size
  
  # 4. 创建路线-景点关联
  route_attractions_data = []
  
  # 为每条路线关联3-5个景点
  routes.each_value do |route|
    sample_attractions = attractions.values.sample(3 + rand(3))
    sample_attractions.each_with_index do |attr, idx|
      route_attractions_data << {
        charter_route_id: route.id,
        attraction_id: attr.id,
        position: idx + 1,
        data_version: '0'
      }
    end
  end
  
  if route_attractions_data.any?
    RouteAttraction.insert_all(route_attractions_data)
    total_route_attractions += route_attractions_data.size
  end
end

puts ""
puts "✓ 数据包加载完成"
puts "数据统计："
puts "  - 城市数: #{CHARTER_CITIES.size}个"
puts "  - 景点总数: #{total_attractions}个"
puts "  - 车型种类: #{vehicle_types_data.size}种"
puts "  - 包车路线: #{total_routes}条"
puts "  - 路线景点关联: #{total_route_attractions}条"
