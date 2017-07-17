package com.lexisnexis.bis.moreover.json.metabase.entities;

import java.util.Date;
import java.util.List;

import org.codehaus.jackson.annotate.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Article {

    private Long sequenceId;

    private Long id;

    private String language;

    private String languageCode;

    private String title;

    private String content;

    private String contentWithMarkup;

    private String extract;
    
    private List<String> tags;
    
    private Long wordCount;

    private Date publishedDate;

    private Date harvestDate;

    private Date embargoDate;

    private Date licenseEndDate;

    private String url;

    private String commentsUrl;

    private List<String> outboundUrls;

    private String dataFormat;

    private String copyright;

    private String loginStatus;

    private Long duplicateGroupId;
    
    private boolean adultLanguage;
    
    private List<License> licenses;

    public Long getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(Long sequenceId) {
        this.sequenceId = sequenceId;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getContentWithMarkup() {
        return contentWithMarkup;
    }

    public void setContentWithMarkup(String contentWithMarkup) {
        this.contentWithMarkup = contentWithMarkup;
    }

    public String getExtract() {
        return extract;
    }

    public void setExtract(String extract) {
        this.extract = extract;
    }

    public Date getPublishedDate() {
        return publishedDate;
    }

    public void setPublishedDate(Date publishedDate) {
        this.publishedDate = publishedDate;
    }

    public Date getHarvestDate() {
        return harvestDate;
    }

    public void setHarvestDate(Date harvestDate) {
        this.harvestDate = harvestDate;
    }

    public Date getEmbargoDate() {
        return embargoDate;
    }

    public void setEmbargoDate(Date embargoDate) {
        this.embargoDate = embargoDate;
    }

    public Date getLicenseEndDate() {
        return licenseEndDate;
    }

    public void setLicenseEndDate(Date licenseEndDate) {
        this.licenseEndDate = licenseEndDate;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getCommentsUrl() {
        return commentsUrl;
    }

    public void setCommentsUrl(String commentsUrl) {
        this.commentsUrl = commentsUrl;
    }

    public List<String> getOutboundUrls() {
        return outboundUrls;
    }

    public void setOutboundUrls(List<String> outboundUrls) {
        this.outboundUrls = outboundUrls;
    }

    public String getDataFormat() {
        return dataFormat;
    }

    public void setDataFormat(String dataFormat) {
        this.dataFormat = dataFormat;
    }

    public String getCopyright() {
        return copyright;
    }

    public void setCopyright(String copyright) {
        this.copyright = copyright;
    }

    public String getLoginStatus() {
        return loginStatus;
    }

    public void setLoginStatus(String loginStatus) {
        this.loginStatus = loginStatus;
    }

    public Long getDuplicateGroupId() {
        return duplicateGroupId;
    }

    public void setDuplicateGroupId(Long duplicateGroupId) {
        this.duplicateGroupId = duplicateGroupId;
    }

    public boolean isAdultLanguage() {
        return adultLanguage;
    }

    public void setAdultLanguage(boolean adultLanguage) {
        this.adultLanguage = adultLanguage;
    }

    public List<License> getLicenses() {
        return licenses;
    }

    public void setLicenses(List<License> licenses) {
        this.licenses = licenses;
    }

    public String getLanguageCode() {
        return languageCode;
    }

    public void setLanguageCode(String languageCode) {
        this.languageCode = languageCode;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }

    public Long getWordCount() {
        return wordCount;
    }

    public void setWordCount(Long wordCount) {
        this.wordCount = wordCount;
    }
    
}
