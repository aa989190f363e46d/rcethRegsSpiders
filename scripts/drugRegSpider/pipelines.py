# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html

from scrapy.pipelines.files import FilesPipeline
from scrapy.http import Request
import os

class DrugregspiderFilesPipeline(FilesPipeline):

    def get_media_requests(self, item, info):
        def already_done(url): 
          return os.path.isfile(self.store._get_filesystem_path('full/%s' % (url.split('/')[-1],)))

        return [Request(x) for x in item.get(self.FILES_URLS_FIELD, []) if not already_done(x)]

    def file_path(self, request, response=None, info=None):        
        image_guid = request.url.split('/')[-1]
        return 'full/%s' % (image_guid)


class DrugregspiderPipeline(object):
    def process_item(self, item, spider):
        return item