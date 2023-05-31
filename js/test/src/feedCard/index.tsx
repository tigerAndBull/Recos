import { Image, Text, View } from "../../../lib/index";

interface NegativeFeedbackReasonItemModel {
    icon: string;
    code: string;
    desc: string;
}

interface NegativeFeedbackModel {
    toast:string;
    reasons: Array<NegativeFeedbackReasonItemModel>;
}

interface FeedLogCtx {
    stidContainer: string;
}

interface TitleTagInfo {
    iconUrl: string;
    width: number;
    height: number;
}

interface ItemCardTagInfo {
    content: string;
    prefix: string;
    picCdnUrl: Array<CDN>;
    picUrl: string;
    tagType: number;
}

interface BrandInfo {
    text: string;
    textColor: string;
    imgUrl: string;
    imgCdnUrl: Array<CDN>;
}

interface CDN {
    cdn: string;
    url: string;
}

interface FeedCardStyleConfig {
    iconImgUrl: string;
    iconText: string;
    bgColorStart: string;
    bgColorEnd: string;
    cardBgImgUrl: string;
    liveLabel: number;
}

export interface RelationItemInfo {
    itemId: number;
    itemTitle: string;
    sourceType: number;
    itemPrice: string;
    imgUrl: string;
    imgCdnUrl: Array<CDN>;
    itemSalesDesc: string;
    jumpUrl: string;
    activityLabel: number;
    commodityTag: string;
    commodityTagType: number;
    commodityTagInfo: CommodityTagInfo;
    marketGoodType: number;
    marketingTagInfo: MarketingTagInfo;
    titleTagInfoList: Array<TitleTagInfo>;
    itemCardTagInfoList: Array<ItemCardTagInfo>;
    // 新增字段
    itemServiceRuleTitleList: string[];
    bottomAction: ShopEntryInfo;
    // 货架商品类型，1: 0元购
    itemType: number;
    itemSellPointList: ItemSellPoint;
    //卡片类型 1 -优化版，2- 竞对版
    cardDisplayType: number;
    itemRankInfo: ItemRankInfo;
}

interface ItemRankInfo {
    rankText: string;
    rankUrl: string;
}

interface ItemSellPoint {
    //1 -0元试穿 2- 低价好物  3 - 90天降价xx% 4-券 5 -物流信息 6-评价 7- 履约 8-信任购
    //9-补贴签 10 - 补贴兜底
    itemSellingType: number;
    itemSellingTitleList: string[];
    itemSellingImg: string;
}

interface ActivityInfo {
    type: number;
    desc: string;
    imgCdnUrl: Array<CDN>;
    pendantType: number;
    countDownTime: number;
    pendantDisappearTime: number;
    extraImgCdn: Array<CDN>;
    promotionId: string;
}

interface TagInfo {
    title: string;
    titleColor: string;
    backgroundColor: string;
}

interface WorkTitleList {}

interface CommodityTagInfo {
    commodityTag: string;
    commodityTagType: number;
    commodityMarketType: number;
    commodityTagColor: string;
}

interface MarketingTagInfo {
    commodityTag: string;
    commodityTagType: number;
    commodityMarketType: number;
    backgroundColor: string;
    titleColor: string;
    iconUrl: string;
    iconCdnUrl: Array<CDN>;
    tagName: string;
}

interface GeneralButton {
    imgUrl: string;
    imgCdnUrl: Array<CDN>;
}

interface TitleTagInfo {
    iconUrl: string;
    width: number;
    height: number;
}

interface ItemCardTagInfo {
    content: string;
    prefix: string;
    picCdnUrl: Array<CDN>;
    picUrl: string;
    tagType: number;
}

interface LocalProps {
    section: number;
    index: number;
    identity: string;
}

interface ShopEntryInfo {
    sellingPointType: number;
    sellingPoint: string;
    sellingPointFontColor: string;
    title: string;
    url: string;
    type: number;
    enteringGuide: string;
}

export interface RelationItemInfo {
    itemId: number;
    itemTitle: string;
    sourceType: number;
    itemPrice: string;
    imgUrl: string;
    imgCdnUrl: Array<CDN>;
    itemSalesDesc: string;
    jumpUrl: string;
    activityLabel: number;
    commodityTag: string;
    commodityTagType: number;
    commodityTagInfo: CommodityTagInfo;
    marketGoodType: number;
    marketingTagInfo: MarketingTagInfo;
    titleTagInfoList: Array<TitleTagInfo>;
    itemCardTagInfoList: Array<ItemCardTagInfo>;
    // 新增字段
    itemServiceRuleTitleList: string[];
    bottomAction: ShopEntryInfo;
    // 货架商品类型，1: 0元购
    itemType: number;
    itemSellPointList: ItemSellPoint;
    //卡片类型 1 -优化版，2- 竞对版
    cardDisplayType: number;
    itemRankInfo: ItemRankInfo;
}

interface Model {
    type: number;
    workId: string;
    bizType: number;
    expTag: string;
    serverExpTag: string;
    llsid: string;
    categoryId: string;
    showFeedbackGuide: boolean;
    negativeFeedback: NegativeFeedbackModel;
    ratio: number;
    feedLogCtx: FeedLogCtx;
    localProps: LocalProps;
    tab_id: number;
    tab_name: string;
    subtab_id: number;
    subtab_name: string;
    tab_style: number;
    planId: string;
    sourceId: string;
    sourceTypeLog: string;
    releaseId: string;
    screenId: string;
    onlineNum: string;
    workTitle: string;
    cardStyle: number;
    cardId: number;
    brandInfo: BrandInfo;
    workPic: string;
    workPicCdn: Array<CDN>;
    avatar: string;
    avatarCdn: Array<CDN>;
    nick: string;
    width: number;
    height: number;
    jumpUrl: string;
    authorId: number;
    ad: boolean;
    autoPlayScore: number;
    feedCardStyleConfig: FeedCardStyleConfig;
    relationItemStyle: number;
    relationItemInfoList: Array<RelationItemInfo>;
    activityInfo: ActivityInfo;
    tagInfo: TagInfo;
    workTitleList: Array<WorkTitleList>;
    generalButton: GeneralButton;
    recommendText: string;
    fansNum: string;
    selectionBagId: string;
}

const style = {
    root: {
        flexDirection: 'column',
        backgroundColor: '#FFFFFF',
        borderRadius: 4,

    },
    cover: {
        width: 200,
        height: 200,
        borderRadius: 5,
        backgroundColor: '#FFFFFF',
    },
    tag: {
        backgroundColor: '#000000',
        fontSize: 14,
        color: '#FFFFFF',
    },
    title: {
        color: '#222222',
        fontSize: 16,
        marginTop: 8,
        marginRight: 8,
        marginLeft: 8,
        fontWeight: 300,
    },
    commodityInfo: {
        flexDirection: 'row',
        alignItems: 'center',
        height: 40,
        marginHorizontal: 8,
        maxWidth: 185,
    },
    icon: {
        width: 30,
        height: 30,
    },
    detailText: {
        fontSize: 14,
        color: '#7FFFAA',
        height: 100,
    },
    payLaterSoldText: {
        fontSize: 10,
        color: '#FFFFFF',
        backgroundColor: '#0000004D',
        paddingHorizontal: 4,
        textAlign: 'center',
        height: 100,
    },
    priceDescContainer: {
        marginTop: 8,
        flexDirection: 'row',
        alignItems: 'flex-end',
        backgroundColor: '#f8f8f8',
        width: 200,
        height: 60,
    },
    piecesSoldText: {
        fontSize: 13,
        color: '#9C9C9C',
        marginLeft: 2,
        marginBottom: 2,
        fontWeight: 300,
    },
    brandInfoContainer: {
        flexDirection: 'row',
        justifyContent: 'spaceBetween',
        alignItems: 'center',
        marginHorizontal: 8,
        marginBottom: 8,
        backgroundColor: '#f8f8f8',
        borderRadius: 3,
        width: 200,
        height: 60,
    },
    brandInfoText: {
        fontSize: 12,
        color: '#666666',
        marginLeft: 4,
        height: 24,
    },
    brandInfoArrow: {
        width: 24,
        height: 24,
        marginRight: 2,
    }
}

function feedCard(feed: Model) {

    let itemInfo = feed.relationItemInfoList[0];
    if (itemInfo == null) return;

    let imageWidth = 150;
    let imageHeight = 150;
    if (feed.ratio != null && feed.ratio > 0) {
        imageHeight = imageWidth / feed.ratio;
    }

    let brandContainerHeight = 20;

    let images = feed.relationItemInfoList;
    let coverUrl = '';
    if (images) {
        console.log('mmmmmmmm');
        let imageUrl = images[0].imgUrl;
        if (imageUrl.length > 0) {
            coverUrl = imageUrl;
        }
    }

    return (<View style={style.root}>
        <Image style={[style.cover, { height: imageHeight }]} url={coverUrl}></Image>
        <Text style={style.title}>{itemInfo.itemTitle}</Text>
        <View style={style.priceDescContainer}>
            <Text style={style.piecesSoldText}>{itemInfo.itemSalesDesc}</Text>
        </View>
        <View style={[style.brandInfoContainer, { height: brandContainerHeight }]}>
            <Image style={style.brandInfoArrow} url={itemInfo.itemRankInfo.rankUrl}></Image>
            <Text style={style.brandInfoText}>{itemInfo.itemRankInfo.rankText}</Text>
        </View>
    </View>);
}