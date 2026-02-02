package com.example.api.service.admin;

import com.example.api.dto.admin.AdminContactResponse;
import com.example.api.dto.admin.ContactStatusUpdateRequest;
import com.example.api.entity.Contact;
import com.example.api.repository.ContactRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminContactService {

    private static final Logger logger = LoggerFactory.getLogger(AdminContactService.class);

    @Autowired
    private ContactRepository contactRepository;

    public AdminContactResponse.ListResponse getContacts(int page, int size, String status) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "contactId"));

        Specification<Contact> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null && !status.isEmpty()) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Contact> contactPage = contactRepository.findAll(spec, pageable);

        List<AdminContactResponse> contacts = contactPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminContactResponse.ListResponse(contacts, page, size, contactPage.getTotalElements(), contactPage.getTotalPages());
    }

    public AdminContactResponse getContact(Long contactId) {
        Contact contact = contactRepository.findById(contactId)
                .orElseThrow(() -> new IllegalArgumentException("お問い合わせが見つかりません: " + contactId));
        return toResponse(contact);
    }

    @Transactional
    public AdminContactResponse updateContactStatus(Long contactId, ContactStatusUpdateRequest request) {
        Contact contact = contactRepository.findById(contactId)
                .orElseThrow(() -> new IllegalArgumentException("お問い合わせが見つかりません: " + contactId));

        contact.setStatus(request.getStatus());
        if (request.getAdminMemo() != null) {
            contact.setAdminMemo(request.getAdminMemo());
        }

        contact = contactRepository.save(contact);
        logger.info("お問い合わせステータス更新: {} -> {}", contactId, request.getStatus());
        return toResponse(contact);
    }

    private AdminContactResponse toResponse(Contact contact) {
        AdminContactResponse response = new AdminContactResponse();
        response.setContactId(contact.getContactId());
        response.setUserId(contact.getUser().getId());
        response.setUserEmail(contact.getUser().getMailaddress());
        response.setTitle(contact.getTitle());
        response.setContactDetail(contact.getContact_detail());
        response.setImageUrl(contact.getImage_url());
        response.setStatus(contact.getStatus());
        response.setAdminMemo(contact.getAdminMemo());
        response.setCreatedAt(contact.getCreatedAt());
        return response;
    }
}
