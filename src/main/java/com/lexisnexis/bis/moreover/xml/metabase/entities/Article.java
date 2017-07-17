package com.lexisnexis.bis.moreover.xml.metabase.entities;

import java.util.Date;
import java.util.List;

import javax.xml.bind.annotation.XmlElement;

public class Article {

    private Long sequenceId;

    private Long id;

    private String language;

    private String languageCode;

    private String title;

    private String content;

    private String contentWithMarkup;

    private String extract;

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
    
    private Licenses licenses;

    @XmlElement
    public Long getSequenceId() {
        return sequenceId;
    }

    public void setSequenceId(Long sequenceId) {
        this.sequenceId = sequenceId;
    }

    @XmlElement
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    @XmlElement
    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    @XmlElement
    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    @XmlElement
    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    @XmlElement
    public String getContentWithMarkup() {
        return contentWithMarkup;
    }

    public void setContentWithMarkup(String contentWithMarkup) {
        this.contentWithMarkup = contentWithMarkup;
    }

    @XmlElement
    public String getExtract() {
        return extract;
    }

    public void setExtract(String extract) {
        this.extract = extract;
    }

    @XmlElement
    public Date getPublishedDate() {
        return publishedDate;
    }

    public void setPublishedDate(Date publishedDate) {
        this.publishedDate = publishedDate;
    }

    @XmlElement
    public Date getHarvestDate() {
        return harvestDate;
    }

    public void setHarvestDate(Date harvestDate) {
        this.harvestDate = harvestDate;
    }

    @XmlElement
    public Date getEmbargoDate() {
        return embargoDate;
    }

    public void setEmbargoDate(Date embargoDate) {
        this.embargoDate = embargoDate;
    }

    @XmlElement
    public Date getLicenseEndDate() {
        return licenseEndDate;
    }

    public void setLicenseEndDate(Date licenseEndDate) {
        this.licenseEndDate = licenseEndDate;
    }

    @XmlElement
    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    @XmlElement
    public String getCommentsUrl() {
        return commentsUrl;
    }

    public void setCommentsUrl(String commentsUrl) {
        this.commentsUrl = commentsUrl;
    }

    @XmlElement
    public List<String> getOutboundUrls() {
        return outboundUrls;
    }

    public void setOutboundUrls(List<String> outboundUrls) {
        this.outboundUrls = outboundUrls;
    }

    @XmlElement
    public String getDataFormat() {
        return dataFormat;
    }

    public void setDataFormat(String dataFormat) {
        this.dataFormat = dataFormat;
    }

    @XmlElement
    public String getCopyright() {
        return copyright;
    }

    public void setCopyright(String copyright) {
        this.copyright = copyright;
    }

    @XmlElement
    public String getLoginStatus() {
        return loginStatus;
    }

    public void setLoginStatus(String loginStatus) {
        this.loginStatus = loginStatus;
    }

    @XmlElement
    public Long getDuplicateGroupId() {
        return duplicateGroupId;
    }

    public void setDuplicateGroupId(Long duplicateGroupId) {
        this.duplicateGroupId = duplicateGroupId;
    }

    @XmlElement
    public boolean isAdultLanguage() {
        return adultLanguage;
    }

    public void setAdultLanguage(boolean adultLanguage) {
        this.adultLanguage = adultLanguage;
    }

    @XmlElement
    public Licenses getLicenses() {
        return licenses;
    }

    public void setLicenses(Licenses licenses) {
        this.licenses = licenses;
    }

    public String getLanguageCode() {
        return languageCode;
    }

    public void setLanguageCode(String languageCode) {
        this.languageCode = languageCode;
    }
    
}
