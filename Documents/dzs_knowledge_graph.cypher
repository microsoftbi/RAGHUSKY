// ============================================================================
// DZS (大侦探) 知识图谱 - Neo4j 构建脚本
// 基于第1-24集剧情内容
// ============================================================================

// ============================================================================
// Part 1: 约束与索引
// ============================================================================
CREATE CONSTRAINT person_name IF NOT EXISTS FOR (n:Person) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT case_name IF NOT EXISTS FOR (n:Case) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT org_name IF NOT EXISTS FOR (n:Organization) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT location_name IF NOT EXISTS FOR (n:Location) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT evidence_name IF NOT EXISTS FOR (n:Evidence) REQUIRE n.name IS UNIQUE;

// ============================================================================
// Part 2: 人物节点 (Person)
// ============================================================================

// --- 执法人员 ---
MERGE (p1:Person {name: '张一昂'})  SET p1.role = '刑警', p1.identity = '执法人员', p1.org = '省公安厅', p1.note = '主角，五年前因破案意外被调离刑侦一线，后重新启用';
MERGE (p2:Person {name: '李茜'})    SET p2.role = '刑警', p2.identity = '执法人员', p2.org = '省公安厅', p2.note = '省厅优秀新人，协助张一昂办案';
MERGE (p3:Person {name: '叶剑'})    SET p3.role = '刑警', p3.identity = '执法人员', p3.org = '三江口公安局', p3.note = '三江口刑警，调查卢正案时被害';
MERGE (p4:Person {name: '王瑞军'})  SET p4.role = '刑警', p4.identity = '执法人员', p4.org = '三江口公安局', p4.note = '三江口刑警，协助专案组';
MERGE (p5:Person {name: '宋星'})    SET p5.role = '民警', p5.identity = '执法人员', p5.org = '三江口公安局', p5.note = '三江口民警';
MERGE (p6:Person {name: '高栋'})    SET p6.role = '副厅长', p6.identity = '执法人员', p6.org = '省公安厅', p6.note = '省厅副厅长，重新启用张一昂';
MERGE (p7:Person {name: '齐振兴'})  SET p7.role = '局长', p7.identity = '执法人员', p7.org = '三江口公安局', p7.note = '三江口公安局局长';
MERGE (p8:Person {name: '陈法医'})  SET p8.role = '法医', p8.identity = '执法人员', p8.org = '三江口公安局', p8.note = '负责叶剑尸检';

// --- 犯罪分子 ---
MERGE (p9:Person {name: '方超'})    SET p9.identity = '犯罪分子', p9.note = '劫匪头目，与刘直搭档流窜作案';
MERGE (p10:Person {name: '刘直'})   SET p10.identity = '犯罪分子', p10.note = '劫匪，方超搭档，不太聪明';
MERGE (p11:Person {name: '朗博图'}) SET p11.identity = '犯罪分子', p11.note = '朗博文弟弟，真凶——杀害叶剑，小名"洋洋"';
MERGE (p12:Person {name: '朗博文'}) SET p12.identity = '犯罪分子', p12.org = '荣城集团', p12.note = '荣城集团核心成员，替弟弟顶罪';
MERGE (p13:Person {name: '朱亦飞'}) SET p13.identity = '犯罪分子', p13.note = '文物贩子，编钟交易中间人';
MERGE (p14:Person {name: '霍正'})   SET p14.identity = '犯罪分子', p14.note = '朱亦飞手下，杀害刘背，后欲报复张一昂';
MERGE (p15:Person {name: '刘背'})   SET p15.identity = '犯罪分子', p15.note = '编钟走私者，被朱亦飞欺骗后被霍正杀害';
MERGE (p16:Person {name: '梅东'})   SET p16.identity = '犯罪分子', p16.note = '洗钱中间人，与周荣有交易';
MERGE (p17:Person {name: '杨威'})   SET p17.identity = '犯罪分子', p17.note = '林凯拜把兄弟，与林凯妻子有染，路虎车主';
MERGE (p18:Person {name: '林凯'})   SET p18.identity = '犯罪分子', p18.note = '方庸前小舅子，被方超刘直锁在后备箱憋死';
MERGE (p19:Person {name: '李峰'})   SET p19.identity = '犯罪分子', p19.note = 'A级通缉犯，蒋英丈夫，在火车站被抓';

// --- 商人/官员 ---
MERGE (p20:Person {name: '周荣'})   SET p20.identity = '商人', p20.org = '荣城集团', p20.note = '荣城集团老板，躁郁症，涉嫌多项犯罪';
MERGE (p21:Person {name: '方庸'})   SET p21.identity = '官员', p21.org = '东部新城管委会', p21.note = '东部新城管委会主任，贪官，后被纪委带走';
MERGE (p22:Person {name: '胡建仁'}) SET p22.identity = '商人', p22.org = '荣城集团', p22.note = '周荣心腹，负责打理各种事务';
MERGE (p23:Person {name: '陆一波'}) SET p23.identity = '商人', p23.org = '荣城集团', p23.note = '周淇男友，举报信书写者';
MERGE (p24:Person {name: '周淇'})   SET p24.identity = '商人', p24.org = '荣城集团', p24.note = '周荣亲戚/下属，陆一波女友';
MERGE (p25:Person {name: '李棚改'}) SET p25.identity = '商人', p25.org = '荣城集团', p25.note = '荣城集团保安队长，后被周荣枪击';
MERGE (p26:Person {name: '杜聪'})   SET p26.identity = '商人', p26.org = '荣城集团', p26.note = '荣城集团员工，开周荣奔驰出车祸';

// --- 底层/配角人物 ---
MERGE (p27:Person {name: '刚哥'})   SET p27.identity = '底层人物', p27.note = '废品回收站老板，与小毛一起捡到夏利车';
MERGE (p28:Person {name: '小毛'})   SET p28.identity = '底层人物', p28.note = '刚哥搭档，开黑出租，抢走霍正箱子';
MERGE (p29:Person {name: '郑勇兵'}) SET p29.identity = '销赃者', p29.note = '方超刘直销赃对象，刘背接头人';
MERGE (p30:Person {name: '蒋英'})   SET p30.identity = '证人', p30.note = '外卖送餐员，李峰妻子，曾给张一昂送餐';
MERGE (p31:Person {name: '小飞'})   SET p31.identity = '底层人物', p31.note = '三江口小有名气的刀疤脸';

// --- 受害者 ---
MERGE (p32:Person {name: '卢正'})   SET p32.identity = '受害者', p32.org = '三江口公安局', p32.role = '副局长', p32.note = '三江口公安局副局长，半年前死于车祸（意外）';

// --- 其他 ---
MERGE (p33:Person {name: '假风水大师'}) SET p33.identity = '骗子', p33.note = '胡建仁找来的风水大师，后讹钱';

// ============================================================================
// Part 3: 案件节点 (Case)
// ============================================================================

MERGE (c1:Case {name: '卢正车祸死亡案'})
  SET c1.type = '命案',
      c1.status = '已结案',
      c1.conclusion = '交通事故意外死亡',
      c1.time = '半年前（故事开始前）',
      c1.description = '三江口副局长卢正死于交通事故，举报信称实为谋杀，最终证实确为意外';

MERGE (c2:Case {name: '叶剑被害案'})
  SET c2.type = '命案',
      c2.status = '已破案',
      c2.time = '第3集',
      c2.description = '刑警叶剑在河岸边被人用绑刀的车撞死，留下"一昂"血字，真凶为朗博图';

MERGE (c3:Case {name: '省城爆炸案'})
  SET c3.type = '爆炸/抢劫',
      c3.status = '已破案',
      c3.time = '第1集',
      c3.description = '方超刘直引爆化粪池后抢劫金店，张一昂在现场捡到关于卢正案的残缺举报信';

MERGE (c4:Case {name: '信用社抢劫案'})
  SET c4.type = '抢劫',
      c4.status = '已破案',
      c4.time = '第1集（五年前）',
      c4.description = '方超刘直抢劫信用社，行为古怪令民警费解';

MERGE (c5:Case {name: '金店抢劫案'})
  SET c5.type = '抢劫',
      c5.status = '已破案',
      c5.time = '第1集',
      c5.description = '方超刘直乔装抢劫金店，刘直错抱不值钱摆设';

MERGE (c6:Case {name: '编钟非法交易案'})
  SET c6.type = '文物走私',
      c6.status = '已破案',
      c6.time = '第15-22集',
      c6.description = '周荣通过朱亦飞购买青铜编钟贿赂方庸，交易中发生火并，朱亦飞坠崖死亡';

MERGE (c7:Case {name: '梅东洗钱案'})
  SET c7.type = '洗钱',
      c7.status = '已破案',
      c7.time = '第14集',
      c7.description = '周荣通过梅东洗钱至海外，张一昂设局抓获梅东';

MERGE (c8:Case {name: '方庸贪腐案'})
  SET c8.type = '贪污腐败',
      c8.status = '已立案',
      c8.time = '第23集',
      c8.description = '东部新城管委会主任方庸涉嫌贪腐，被纪委带走，方超提供关键线索';

MERGE (c9:Case {name: '周荣庄园抢劫案'})
  SET c9.type = '抢劫',
      c9.status = '已破案',
      c9.time = '第17集/第23集',
      c9.description = '方超刘直两次抢劫周荣庄园，第一次抢走美元箱和手机，第二次与周荣对峙';

MERGE (c10:Case {name: '方超刘直连环抢劫案'})
  SET c10.type = '系列抢劫',
      c10.status = '已破案',
      c10.description = '方超刘直从省城到三江口的系列抢劫行为总称';

// ============================================================================
// Part 4: 组织节点 (Organization)
// ============================================================================

MERGE (o1:Organization {name: '省公安厅'})
  SET o1.type = '执法机构', o1.location = '省城';
MERGE (o2:Organization {name: '三江口公安局'})
  SET o2.type = '执法机构', o2.location = '三江口';
MERGE (o3:Organization {name: '荣城集团'})
  SET o3.type = '民营企业', o3.location = '三江口', o3.note = '周荣控制的集团公司';
MERGE (o4:Organization {name: '东部新城管委会'})
  SET o4.type = '政府机构', o4.location = '三江口', o4.note = '方庸主管的政府机构';
MERGE (o5:Organization {name: '枫林晚酒店'})
  SET o5.type = '酒店/会所', o5.location = '三江口', o5.note = '高端水疗酒店，多名人物交汇处';
MERGE (o6:Organization {name: '三江口日报社'})
  SET o6.type = '媒体', o6.location = '三江口';
MERGE (o7:Organization {name: '废品回收站'})
  SET o7.type = '个体经营', o7.location = '三江口', o7.note = '刚哥小毛的据点';

// ============================================================================
// Part 5: 地点节点 (Location)
// ============================================================================

MERGE (l1:Location {name: '三江口市'})    SET l1.type = '城市';
MERGE (l2:Location {name: '省城'})        SET l2.type = '城市';
MERGE (l3:Location {name: '周荣庄园'})    SET l3.type = '住宅', l3.note = '周荣的豪华庄园，编钟交易和周荣庄园抢劫案发生地';
MERGE (l4:Location {name: '方庸家'})      SET l4.type = '住宅', l4.note = '方庸住处，收藏大量文玩字画';
MERGE (l5:Location {name: '枫林晚酒店'})  SET l5.type = '商业场所', l5.note = '高端水疗酒店，叶剑曾持贵宾卡';
MERGE (l6:Location {name: '东部新城'})    SET l6.type = '开发区', l6.note = '东部新城开发区，周荣和方庸的利益焦点';
MERGE (l7:Location {name: '郑勇兵住处'})  SET l7.type = '住宅', l7.note = '方超刘直销赃地，刘背接头处';
MERGE (l8:Location {name: '废品回收站'})  SET l8.type = '经营场所', l8.note = '刚哥小毛据点，方超刘直弃夏利处';
MERGE (l9:Location {name: '高速服务区'})  SET l9.type = '交通枢纽', l9.note = '林凯被发现死亡的地点';
MERGE (l10:Location {name: '三江口火车站'}) SET l10.type = '交通枢纽', l10.note = '张一昂抓捕李峰的地点';
MERGE (l11:Location {name: '河岸边'})     SET l11.type = '户外', l11.note = '叶剑遇害地，留下"一昂"血字石头';
MERGE (l12:Location {name: '荣城集团大楼'}) SET l12.type = '办公场所', l12.note = '荣城集团总部';
MERGE (l13:Location {name: '三江口公安局档案室'}) SET l13.type = '办公场所';
MERGE (l14:Location {name: '涵洞'})       SET l14.type = '户外', l14.note = '刚哥小毛藏身处，李棚改在此摔昏';
MERGE (l15:Location {name: '枯井'})       SET l15.type = '户外', l15.note = '方超刘直踩点时被困三天';

// ============================================================================
// Part 6: 关键物品/证据节点 (Evidence)
// ============================================================================

MERGE (e1:Evidence {name: '残缺举报信'})
  SET e1.type = '书证',
      e1.description = '陆一波书写，声称卢正之死是谋杀，张一昂在省城爆炸案现场捡到';
MERGE (e2:Evidence {name: '朗博文手机'})
  SET e2.type = '电子证据',
      e2.description = '存有卢正车祸现场证据，被周荣销毁后在书房被霍正捡到，后被方超刘直抢走';
MERGE (e3:Evidence {name: '限量电子表'})
  SET e3.type = '物证',
      e3.description = '陆一波从朗博文处获得，出现在卢正车祸现场视频中，叶剑死前曾调查此表';
MERGE (e4:Evidence {name: '青铜编钟'})
  SET e4.type = '文物/赃物',
      e4.description = '周荣欲通过朱亦飞购买以贿赂方庸，刘背从水路运入三江口';
MERGE (e5:Evidence {name: '假玉财神像'})
  SET e5.type = '赃物',
      e5.description = '省城金店抢劫案赃物，方超刘直销赃给郑勇兵，后胡建仁买走送周荣';
MERGE (e6:Evidence {name: '美元定金箱'})
  SET e6.type = '赃物/证据',
      e6.description = '周荣准备支付编钟的100万美元定金，内装定位器，被方超刘直抢走';
MERGE (e7:Evidence {name: '路虎车'})
  SET e7.type = '赃物/作案工具',
      e7.description = '林凯从杨威处借得，被方超刘直抢走，林凯被锁后备箱致死';
MERGE (e8:Evidence {name: '破夏利车'})
  SET e8.type = '作案工具/证据',
      e8.description = '方超刘直购买的二手车，刹车失灵，后被改造成黑出租';
MERGE (e9:Evidence {name: '枫林晚水疗贵宾卡'})
  SET e9.type = '线索',
      e9.description = '叶剑家中发现的未使用贵宾卡，引导张一昂调查枫林晚';
MERGE (e10:Evidence {name: '手枪'})
  SET e10.type = '凶器',
      e10.description = '周荣持有的手枪，在庄园对峙中使用';
MERGE (e11:Evidence {name: '一昂血字石头'})
  SET e11.type = '物证',
      e11.description = '叶剑临死前在河岸边用血写下"一昂"，实为暗示朗博图小名"洋洋"';
MERGE (e12:Evidence {name: '绑刀的车'})
  SET e12.type = '凶器',
      e12.description = '朗博图杀害叶剑的凶器——车前绑着刀';

// ============================================================================
// Part 7: 人物 ↔ 人物 关系
// ============================================================================

// --- 上下级关系 (SUPERIOR_TO) ---
MATCH (a:Person {name: '高栋'}), (b:Person {name: '张一昂'}) MERGE (a)-[:SUPERIOR_TO {note: '副厅长→下属'}]->(b);
MATCH (a:Person {name: '高栋'}), (b:Person {name: '李茜'}) MERGE (a)-[:SUPERIOR_TO {note: '副厅长→下属'}]->(b);
MATCH (a:Person {name: '齐振兴'}), (b:Person {name: '王瑞军'}) MERGE (a)-[:SUPERIOR_TO {note: '局长→下属'}]->(b);
MATCH (a:Person {name: '齐振兴'}), (b:Person {name: '宋星'}) MERGE (a)-[:SUPERIOR_TO {note: '局长→下属'}]->(b);
MATCH (a:Person {name: '齐振兴'}), (b:Person {name: '叶剑'}) MERGE (a)-[:SUPERIOR_TO {note: '局长→下属'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '胡建仁'}) MERGE (a)-[:SUPERIOR_TO {note: '老板→心腹'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '李棚改'}) MERGE (a)-[:SUPERIOR_TO {note: '老板→保安队长'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '朗博文'}) MERGE (a)-[:SUPERIOR_TO {note: '老板→下属'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '周淇'}) MERGE (a)-[:SUPERIOR_TO {note: '老板/亲戚→下属'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '杜聪'}) MERGE (a)-[:SUPERIOR_TO {note: '老板→员工'}]->(b);
MATCH (a:Person {name: '胡建仁'}), (b:Person {name: '李棚改'}) MERGE (a)-[:SUPERIOR_TO {note: '上级→保安队长'}]->(b);
MATCH (a:Person {name: '方庸'}), (b:Person {name: '林凯'}) MERGE (a)-[:SUPERIOR_TO {note: '前姐夫→前小舅子'}]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '李茜'}) MERGE (a)-[:SUPERIOR_TO {note: '前辈→新人'}]->(b);

// --- 同事关系 (COLLEAGUE_WITH) ---
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '王瑞军'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '宋星'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '李茜'}), (b:Person {name: '宋星'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '李茜'}), (b:Person {name: '王瑞军'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '王瑞军'}), (b:Person {name: '宋星'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Person {name: '王瑞军'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);
MATCH (a:Person {name: '齐振兴'}), (b:Person {name: '陈法医'}) MERGE (a)-[:COLLEAGUE_WITH]->(b);

// --- 兄弟关系 (SIBLING_OF) ---
MATCH (a:Person {name: '朗博文'}), (b:Person {name: '朗博图'}) MERGE (a)-[:SIBLING_OF]->(b);

// --- 情侣关系 (IN_RELATIONSHIP_WITH) ---
MATCH (a:Person {name: '陆一波'}), (b:Person {name: '周淇'}) MERGE (a)-[:IN_RELATIONSHIP_WITH]->(b);
MATCH (a:Person {name: '蒋英'}), (b:Person {name: '李峰'}) MERGE (a)-[:IN_RELATIONSHIP_WITH {note: '夫妻'}]->(b);
MATCH (a:Person {name: '杨威'}), (b:Person {name: '林凯'}) MERGE (a)-[:IN_RELATIONSHIP_WITH {note: '杨威与林凯妻子有染'}]->(b);

// --- 合作关系 (COOPERATES_WITH) ---
MATCH (a:Person {name: '方超'}), (b:Person {name: '刘直'}) MERGE (a)-[:COOPERATES_WITH {note: '抢劫搭档'}]->(b);
MATCH (a:Person {name: '朱亦飞'}), (b:Person {name: '霍正'}) MERGE (a)-[:COOPERATES_WITH {note: '老板与马仔'}]->(b);
MATCH (a:Person {name: '刚哥'}), (b:Person {name: '小毛'}) MERGE (a)-[:COOPERATES_WITH {note: '废品站搭档'}]->(b);

// --- 杀害关系 (KILLED) ---
MATCH (a:Person {name: '朗博图'}), (b:Person {name: '叶剑'}) MERGE (a)-[:KILLED {method: '用绑刀的车撞死', reason: '灭口——叶剑发现了手表线索'}]->(b);
MATCH (a:Person {name: '霍正'}), (b:Person {name: '刘背'}) MERGE (a)-[:KILLED {method: '火并枪杀', reason: '朱亦飞指使'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Person {name: '林凯'}) MERGE (a)-[:KILLED {method: '锁在后备箱闷死', reason: '意外——抢车后遗忘'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Person {name: '林凯'}) MERGE (a)-[:KILLED {method: '锁在后备箱闷死', reason: '意外——抢车后遗忘'}]->(b);

// --- 威胁/勒索关系 (BLACKMAILED) ---
MATCH (a:Person {name: '方超'}), (b:Person {name: '周荣'}) MERGE (a)-[:BLACKMAILED {amount: '2000万', item: '朗博文手机'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Person {name: '周荣'}) MERGE (a)-[:BLACKMAILED {amount: '2000万', item: '朗博文手机'}]->(b);

// --- 包庇关系 (COVERED_UP_FOR) ---
MATCH (a:Person {name: '朗博文'}), (b:Person {name: '朗博图'}) MERGE (a)-[:COVERED_UP_FOR {note: '哥哥替弟弟顶罪，谎称自己杀害叶剑'}]->(b);

// --- 举报关系 (REPORTED) ---
MATCH (a:Person {name: '陆一波'}), (b:Person {name: '周荣'}) MERGE (a)-[:REPORTED {method: '写举报信', content: '举报周荣多项罪名及卢正之死'}]->(b);

// --- 指使关系 (ORDERED) ---
MATCH (a:Person {name: '周荣'}), (b:Person {name: '胡建仁'}) MERGE (a)-[:ORDERED {task: '疏通方庸关系、处理各种事务'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '朗博文'}) MERGE (a)-[:ORDERED {task: '赎回手机、处理浑水'}]->(b);
MATCH (a:Person {name: '朱亦飞'}), (b:Person {name: '霍正'}) MERGE (a)-[:ORDERED {task: '抓捕刘背、取回编钟'}]->(b);

// --- 销赃关系 (FENCED_TO) ---
MATCH (a:Person {name: '方超'}), (b:Person {name: '郑勇兵'}) MERGE (a)-[:FENCED_TO {item: '假玉财神等金店赃物'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Person {name: '郑勇兵'}) MERGE (a)-[:FENCED_TO {item: '假玉财神等金店赃物'}]->(b);

// --- 交易关系 (TRANSACTED_WITH) ---
MATCH (a:Person {name: '周荣'}), (b:Person {name: '朱亦飞'}) MERGE (a)-[:TRANSACTED_WITH {item: '青铜编钟', amount: '100万美元'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Person {name: '梅东'}) MERGE (a)-[:TRANSACTED_WITH {item: '洗钱服务'}]->(b);
MATCH (a:Person {name: '胡建仁'}), (b:Person {name: '郑勇兵'}) MERGE (a)-[:TRANSACTED_WITH {item: '字画/假玉财神'}]->(b);

// --- 抓捕关系 (ARRESTED) ---
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '李峰'}) MERGE (a)-[:ARRESTED {location: '三江口火车站'}]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '梅东'}) MERGE (a)-[:ARRESTED {location: '地下车库垃圾车'}]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Person {name: '周荣'}) MERGE (a)-[:ARRESTED {location: '周荣庄园'}]->(b);

// ============================================================================
// Part 8: 人物 ↔ 案件 关系
// ============================================================================

// --- 调查关系 (INVESTIGATES) ---
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:INVESTIGATES {role: '主办'}]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '梅东洗钱案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '周荣庄园抢劫案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '李茜'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:INVESTIGATES {role: '协办'}]->(b);
MATCH (a:Person {name: '李茜'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:INVESTIGATES]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:INVESTIGATES {note: '死前正在重新调查此案'}]->(b);
MATCH (a:Person {name: '王瑞军'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:INVESTIGATES {role: '协办'}]->(b);

// --- 被害关系 (VICTIM_OF) ---
MATCH (a:Person {name: '卢正'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:VICTIM_OF]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:VICTIM_OF]->(b);
MATCH (a:Person {name: '刘背'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:VICTIM_OF]->(b);
MATCH (a:Person {name: '林凯'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:VICTIM_OF {note: '被抢走路虎后锁在后备箱致死'}]->(b);

// --- 目击关系 (WITNESSED) ---
MATCH (a:Person {name: '李茜'}), (b:Case {name: '周荣庄园抢劫案'}) MERGE (a)-[:WITNESSED {note: '被打晕前模糊目击方超刘直抢劫过程'}]->(b);

// --- 供述关系 (CONFESSED_TO) ---
MATCH (a:Person {name: '刘直'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:CONFESSED_TO]->(b);
MATCH (a:Person {name: '朗博图'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:CONFESSED_TO {note: '在机场被截获后供认'}]->(b);
MATCH (a:Person {name: '朗博文'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:CONFESSED_TO {note: '先假意供认替弟弟顶罪，后翻供'}]->(b);

// --- 涉嫌关系 (SUSPECTED_OF) ---
MATCH (a:Person {name: '张一昂'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:SUSPECTED_OF {note: '被短暂怀疑——叶剑留下"一昂"血字、有未接来电'}]->(b);

// --- 关联关系 (INVOLVED_IN) ---
MATCH (a:Person {name: '陆一波'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:INVOLVED_IN {role: '举报人', note: '举报信书写者，在爆炸案现场被张一昂捡到举报信'}]->(b);
MATCH (a:Person {name: '陆一波'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:INVOLVED_IN {role: '举报人'}]->(b);
MATCH (a:Person {name: '陆一波'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:INVOLVED_IN {role: '关键证人', note: '叶剑遇害当晚在枫林晚，手表是关键线索'}]->(b);
MATCH (a:Person {name: '胡建仁'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:INVOLVED_IN {role: '买方代表'}]->(b);
MATCH (a:Person {name: '胡建仁'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:INVOLVED_IN {role: '赃物购买者', note: '购买了爆炸案赃物假玉财神'}]->(b);
MATCH (a:Person {name: '朱亦飞'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:INVOLVED_IN {role: '中间人/卖方'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:INVOLVED_IN {role: '买方'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Case {name: '梅东洗钱案'}) MERGE (a)-[:INVOLVED_IN {role: '客户'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Case {name: '方庸贪腐案'}) MERGE (a)-[:INVOLVED_IN {role: '行贿方'}]->(b);
MATCH (a:Person {name: '方庸'}), (b:Case {name: '方庸贪腐案'}) MERGE (a)-[:INVOLVED_IN {role: '被调查对象'}]->(b);
MATCH (a:Person {name: '方庸'}), (b:Case {name: '编钟非法交易案'}) MERGE (a)-[:INVOLVED_IN {role: '受贿目标', note: '周荣买编钟是为了贿赂方庸'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Case {name: '方庸贪腐案'}) MERGE (a)-[:INVOLVED_IN {role: '线索提供者', note: '提供方庸贪腐关键线索'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:INVOLVED_IN {role: '主犯'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:INVOLVED_IN {role: '从犯'}]->(b);
MATCH (a:Person {name: '周淇'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:INVOLVED_IN {role: '赃物购买者', note: '佩戴了省城爆炸案赃物金器'}]->(b);
MATCH (a:Person {name: '朗博图'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:INVOLVED_IN {role: '间接关联', note: '朗博文手机存有车祸真相'}]->(b);

// ============================================================================
// Part 9: 人物 ↔ 物品 关系
// ============================================================================

// --- 拥有关系 (OWNS) ---
MATCH (a:Person {name: '朗博文'}), (b:Evidence {name: '限量电子表'}) MERGE (a)-[:OWNS {note: '后转给陆一波'}]->(b);
MATCH (a:Person {name: '朗博文'}), (b:Evidence {name: '朗博文手机'}) MERGE (a)-[:OWNS {note: '存有卢正车祸真相，后被周荣销毁后在书房被霍正捡到'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Evidence {name: '美元定金箱'}) MERGE (a)-[:OWNS {note: '编钟交易的100万美元定金'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Evidence {name: '手枪'}) MERGE (a)-[:OWNS {note: '庄园对峙中使用'}]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Evidence {name: '枫林晚水疗贵宾卡'}) MERGE (a)-[:OWNS {note: '未使用，死后在家中被子发现'}]->(b);
MATCH (a:Person {name: '林凯'}), (b:Evidence {name: '路虎车'}) MERGE (a)-[:OWNS {note: '从杨威处借得'}]->(b);

// --- 发现关系 (DISCOVERED) ---
MATCH (a:Person {name: '张一昂'}), (b:Evidence {name: '残缺举报信'}) MERGE (a)-[:DISCOVERED {location: '省城爆炸案现场'}]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Evidence {name: '限量电子表'}) MERGE (a)-[:DISCOVERED {note: '在卢正车祸现场视频中发现此表'}]->(b);
MATCH (a:Person {name: '李茜'}), (b:Evidence {name: '限量电子表'}) MERGE (a)-[:DISCOVERED {note: '在郑勇兵家照片中认出此表与叶剑调查的表相同'}]->(b);
MATCH (a:Person {name: '霍正'}), (b:Evidence {name: '朗博文手机'}) MERGE (a)-[:DISCOVERED {note: '在周荣书房偶然捡到'}]->(b);
MATCH (a:Person {name: '宋星'}), (b:Evidence {name: '枫林晚水疗贵宾卡'}) MERGE (a)-[:DISCOVERED {note: '在叶剑家中整理遗物时发现'}]->(b);

// --- 留下关系 (LEFT_BEHIND) ---
MATCH (a:Person {name: '叶剑'}), (b:Evidence {name: '一昂血字石头'}) MERGE (a)-[:LEFT_BEHIND {note: '临死前用血写下"一昂"，实指朗博图小名"洋洋"'}]->(b);

// --- 使用关系 (USED) ---
MATCH (a:Person {name: '朗博图'}), (b:Evidence {name: '绑刀的车'}) MERGE (a)-[:USED {note: '用绑刀的车撞死叶剑'}]->(b);
MATCH (a:Person {name: '周荣'}), (b:Evidence {name: '手枪'}) MERGE (a)-[:USED {note: '开枪打伤李棚改'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Evidence {name: '路虎车'}) MERGE (a)-[:USED {note: '从林凯处抢来使用'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Evidence {name: '路虎车'}) MERGE (a)-[:USED {note: '从林凯处抢来使用'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Evidence {name: '破夏利车'}) MERGE (a)-[:USED {note: '购买后用于跟踪周荣'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Evidence {name: '破夏利车'}) MERGE (a)-[:USED {note: '购买后用于跟踪周荣'}]->(b);
MATCH (a:Person {name: '刚哥'}), (b:Evidence {name: '破夏利车'}) MERGE (a)-[:USED {note: '改造成黑出租'}]->(b);

// --- 销赃购买关系 (BOUGHT_STOLEN) ---
MATCH (a:Person {name: '胡建仁'}), (b:Evidence {name: '假玉财神像'}) MERGE (a)-[:BOUGHT_STOLEN {note: '从郑勇兵处购买，送给周荣'}]->(b);
MATCH (a:Person {name: '周淇'}), (b:Evidence {name: '假玉财神像'}) MERGE (a)-[:BOUGHT_STOLEN {note: '购买了省城爆炸案赃物金器（周淇佩戴的金器）'}]->(b);

// ============================================================================
// Part 10: 人物 ↔ 组织 关系
// ============================================================================

// --- 隶属关系 (BELONGS_TO) ---
MATCH (a:Person {name: '张一昂'}), (b:Organization {name: '省公安厅'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '李茜'}), (b:Organization {name: '省公安厅'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '高栋'}), (b:Organization {name: '省公安厅'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '叶剑'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '王瑞军'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '宋星'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '齐振兴'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '陈法医'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '周荣'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '胡建仁'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '朗博文'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '周淇'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '陆一波'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '李棚改'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '杜聪'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:BELONGS_TO]->(b);
MATCH (a:Person {name: '方庸'}), (b:Organization {name: '东部新城管委会'}) MERGE (a)-[:BELONGS_TO]->(b);

// --- 控制关系 (CONTROLS) ---
MATCH (a:Person {name: '周荣'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:CONTROLS]->(b);
MATCH (a:Person {name: '方庸'}), (b:Organization {name: '东部新城管委会'}) MERGE (a)-[:CONTROLS]->(b);

// ============================================================================
// Part 11: 案件 ↔ 物品 关系
// ============================================================================

// --- 线索指向 (CLUE_TO) ---
MATCH (a:Evidence {name: '残缺举报信'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:CLUE_TO {note: '声称卢正之死是谋杀，引发重新调查'}]->(b);
MATCH (a:Evidence {name: '限量电子表'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:CLUE_TO {note: '出现在车祸现场视频中'}]->(b);
MATCH (a:Evidence {name: '限量电子表'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:CLUE_TO {note: '叶剑因追查此表而被害'}]->(b);
MATCH (a:Evidence {name: '朗博文手机'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:CLUE_TO {note: '存有车祸真相证据'}]->(b);
MATCH (a:Evidence {name: '一昂血字石头'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:CLUE_TO {note: '关键线索——"一昂"实指朗博图小名"洋洋"'}]->(b);
MATCH (a:Evidence {name: '枫林晚水疗贵宾卡'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:CLUE_TO {note: '引导调查方向至枫林晚酒店'}]->(b);

// --- 凶器关系 (WEAPON_OF) ---
MATCH (a:Evidence {name: '绑刀的车'}), (b:Case {name: '叶剑被害案'}) MERGE (a)-[:WEAPON_OF]->(b);

// --- 赃物关系 (LOOT_OF) ---
MATCH (a:Evidence {name: '假玉财神像'}), (b:Case {name: '省城爆炸案'}) MERGE (a)-[:LOOT_OF]->(b);
MATCH (a:Evidence {name: '美元定金箱'}), (b:Case {name: '周荣庄园抢劫案'}) MERGE (a)-[:LOOT_OF]->(b);
MATCH (a:Evidence {name: '路虎车'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:LOOT_OF]->(b);

// ============================================================================
// Part 12: 案件 ↔ 案件 关系
// ============================================================================

MATCH (a:Case {name: '省城爆炸案'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:LED_TO {note: '爆炸案现场的举报信引出卢正案重新调查'}]->(b);
MATCH (a:Case {name: '叶剑被害案'}), (b:Case {name: '卢正车祸死亡案'}) MERGE (a)-[:LINKED_TO {note: '叶剑因重新调查卢正案发现手表线索而被害'}]->(b);
MATCH (a:Case {name: '省城爆炸案'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Case {name: '信用社抢劫案'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Case {name: '金店抢劫案'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Case {name: '周荣庄园抢劫案'}), (b:Case {name: '方超刘直连环抢劫案'}) MERGE (a)-[:PART_OF]->(b);
MATCH (a:Case {name: '编钟非法交易案'}), (b:Case {name: '方庸贪腐案'}) MERGE (a)-[:LED_TO {note: '编钟是周荣贿赂方庸的筹码'}]->(b);
MATCH (a:Case {name: '梅东洗钱案'}), (b:Case {name: '方庸贪腐案'}) MERGE (a)-[:LINKED_TO {note: '周荣洗钱的最终目的是转移贪腐资产'}]->(b);

// ============================================================================
// Part 13: 案件 ↔ 地点 关系
// ============================================================================

MATCH (a:Case {name: '卢正车祸死亡案'}), (b:Location {name: '三江口市'}) MERGE (a)-[:HAPPENED_AT]->(b);
MATCH (a:Case {name: '叶剑被害案'}), (b:Location {name: '河岸边'}) MERGE (a)-[:HAPPENED_AT]->(b);
MATCH (a:Case {name: '省城爆炸案'}), (b:Location {name: '省城'}) MERGE (a)-[:HAPPENED_AT]->(b);
MATCH (a:Case {name: '编钟非法交易案'}), (b:Location {name: '周荣庄园'}) MERGE (a)-[:HAPPENED_AT]->(b);
MATCH (a:Case {name: '梅东洗钱案'}), (b:Location {name: '三江口市'}) MERGE (a)-[:HAPPENED_AT]->(b);
MATCH (a:Case {name: '周荣庄园抢劫案'}), (b:Location {name: '周荣庄园'}) MERGE (a)-[:HAPPENED_AT]->(b);

// ============================================================================
// Part 14: 案件 ↔ 组织 关系
// ============================================================================

MATCH (a:Case {name: '卢正车祸死亡案'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:INVOLVES_ORG]->(b);
MATCH (a:Case {name: '叶剑被害案'}), (b:Organization {name: '三江口公安局'}) MERGE (a)-[:INVOLVES_ORG]->(b);
MATCH (a:Case {name: '叶剑被害案'}), (b:Organization {name: '省公安厅'}) MERGE (a)-[:INVOLVES_ORG]->(b);
MATCH (a:Case {name: '编钟非法交易案'}), (b:Organization {name: '荣城集团'}) MERGE (a)-[:INVOLVES_ORG]->(b);
MATCH (a:Case {name: '方庸贪腐案'}), (b:Organization {name: '东部新城管委会'}) MERGE (a)-[:INVOLVES_ORG]->(b);

// ============================================================================
// Part 15: 关键人物在关键地点的关系
// ============================================================================

MATCH (a:Person {name: '叶剑'}), (b:Location {name: '河岸边'}) MERGE (a)-[:DIED_AT]->(b);
MATCH (a:Person {name: '张一昂'}), (b:Location {name: '周荣庄园'}) MERGE (a)-[:WENT_TO {note: '带队查案，最终在此逮捕周荣'}]->(b);
MATCH (a:Person {name: '方超'}), (b:Location {name: '枯井'}) MERGE (a)-[:TRAPPED_IN {note: '踩点时掉入枯井被困三天'}]->(b);
MATCH (a:Person {name: '刘直'}), (b:Location {name: '枯井'}) MERGE (a)-[:TRAPPED_IN {note: '踩点时掉入枯井被困三天'}]->(b);
MATCH (a:Person {name: '李棚改'}), (b:Location {name: '涵洞'}) MERGE (a)-[:INJURED_AT {note: '追捕刚哥小毛时失足摔倒昏迷'}]->(b);

// ============================================================================
// 脚本结束
// ============================================================================