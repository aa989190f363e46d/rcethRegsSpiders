# -*- coding: utf-8 -*-
import scrapy
from drugRegSpider.items import DrugregspiderItem
from scrapy.http import FormRequest
from urllib2 import unquote
import logging
import os

class InstrspiderSpider(scrapy.Spider):
    name            = "instrSpider"
    allowed_domains = ["rceth.by"]
    #start_urls = (
    #    'http://www.rceth.by/',
    #

    def _file_already_done(self, url): 
          #return os.path.isfile('/home/muzzy/Desktop/drugRegSpider/data/pdfs/full/%s' % (url.split('/')[-1],))    
          return False

    def _getReq(self, letter, pageNum = 1, controllerState = u''):
        
        logging.warning(u"Make query %s-%i" % (letter,pageNum))        

        _url = u'http://rceth.by/Refbank/reestr_lekarstvennih_sredstv/results'
        _frmRqst = {u'FProps[0].IsText':          u'True',
        u'FProps[0].Name':                        u'N_LP',
        u'FProps[0].CritElems[0].Num':            u'1',
        u'FProps[0].CritElems[0].Val':            letter,
        u'FProps[0].CritElems[0].Crit':           u'Start',
        u'FProps[0].CritElems[0].Excl':           u'false',
        u'FOpt.VFiles':                           u'true',
        u'FOpt.VFiles':                           u'false',
        u'FOpt.VEField1':                         u'false',
        u'IsPostBack':                            u'true',
        u'PropSubmit':                            u'FOpt_PageN',
        u'ValueSubmit':                           u'%i' % (pageNum,),
        u'FOpt.PageC':                            u'100',
        u'FOpt.OrderBy':                          u'N_LP',
        u'FOpt.DirOrder':                         u'asc',
        u'FOpt.VFiles':                           u'true',
        u'FOpt.VFiles':                           u'false',
        u'FOpt.VEField1':                         u'true',
        u'FOpt.VEField1':                         u'false',
        u'QueryStringFind':                       controllerState
        }
        
        return FormRequest(_url, formdata=_frmRqst, callback=self.parse)

    def start_requests(self):
        _initSeq = u'АБВГДЕЖЗИКЛМНОПРСТУФХЦЧЭЮЯ0123456789'
        #_initSeq = u'Л'
        self.traversed = {l:[] for l in _initSeq}
        return [self._getReq(l) for l in _initSeq]

    def parse(self, response):
        currLetter = filter(lambda x: x.startswith(u'FProps[0].CritElems[0].Val='),unquote(response.request.body).decode('utf-8').split('&'))[0][27]
        currPageNum = int(filter(lambda x: x.startswith(u'ValueSubmit='),unquote(response.request.body).decode('utf-8').split('&'))[0][12:])
        
        logging.warning(u"CurrLetter is %s-%s`" % (currLetter,currPageNum))
        
        for i in xrange(1,len(response.xpath('//a[@name="FOpt_PageN"]'))):
            if not i in self.traversed[currLetter]:
                controllerState = response.xpath(u'//input[@id="QueryStringFind"]/@value').extract()[0]          
                self.traversed[currLetter].append(i)
                yield self._getReq(currLetter,i+1, controllerState)

        for tr in response.xpath('//div[@class="table-view"]/table/tbody/tr'):
            currItem = DrugregspiderItem()
            currItem["name"]              = tr.xpath('td')[1].xpath('a/text()').extract()[0]
            currItem["mnn"]               = tr.xpath('td')[2].xpath('text()').extract()[0].strip()
            currItem["lForm"]             = tr.xpath('td')[3].xpath('text()').extract()[0].strip()            
            currItem["manufacturer"]      = tr.xpath('td')[4].xpath('text()').extract()[0].strip()
            currItem["invoker"]           = tr.xpath('td')[5].xpath('text()').extract()[0].strip()
            currItem["certNum"]           = tr.xpath('td')[6].xpath('text()').extract()[0].strip()
            currItem["regDtBegin"]        = tr.xpath('td')[7].xpath('text()').extract()[0].strip()
            currItem["regDtExpire"]       = tr.xpath('td')[8].xpath('text()').extract()[0].strip()
            currItem["originality"]       = tr.xpath('td')[9].xpath('text()').extract()[0].strip()
            currItem["manuals"]           = ''.join(tr.xpath('td')[1].xpath('span/a').extract())
            currItem["file_urls"]           = [u for u in [u'http://www.rceth.by%s' % (href,) for href in tr.xpath('td')[1].xpath('span/a/@href').extract()] if not self._file_already_done(u)]

            yield currItem
            

