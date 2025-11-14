package com.example.api.service;

import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {
    private final UserRepository userRepository;
    public UserService(UserRepository userRepository){ this.userRepository = userRepository; }

    public List<User> list(){ return userRepository.findAll(); }

    public Optional<User> findByUsername(String username){
        return userRepository.findByUsername(username);
    }

    @Transactional
    @NonNull
    @SuppressWarnings("null") // Hikari/JPA の戻り値に対する IDE の誤検知を抑制
    public User create(User user){
        return userRepository.save(user);
    }
}
