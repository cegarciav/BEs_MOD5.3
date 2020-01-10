import scipy.io.wavfile as wav
import numpy as np
import os
from random import shuffle
import pickle
import time
import matplotlib.pyplot as plt

start = time.time()

################################################
#                                              #
#  Initialisation des variables et paramètres  #
#                                              #
################################################

#path = "../spoken_digit_dataset/"
path = "spoken_digit_dataset/"
duree_trame = 0.030
ordre = 10
omega_v, omega_d, omega_h = 1, 1, 1

parametres = [duree_trame, ordre, omega_v, omega_d, omega_h]
with open("parametres.txt", "wb") as fp:
    pickle.dump(parametres, fp)

#################################
#                               #
#  Calcul des coefficients LPC  #
#                               #
#################################

def get_r_vector(window):
    r_vector = []
    for index in range(ordre + 1):
        vect_1 = window[:len(window) - index]
        vect_2 = window[index:]
        r_vector.append(sum(vect_1 * vect_2) / len(vect_1))
    return r_vector

def get_r_matrix(r_vector):
    size = len(r_vector)
    mat = np.zeros((size, size))
    for i in range(size):
        for j in range(size):
            mat[i, j] = r_vector[abs(i - j)]
    return mat

def get_a_vector(matrix):
    inverse_m = np.linalg.inv(matrix)
    sigma_vector = np.zeros(len(matrix))
    sigma_vector[0] = 1
    mult = np.dot(inverse_m, sigma_vector)
    a_vector = mult / mult[0]
    return a_vector[1:]

def lpc_coeffs(window):
    r_vector = get_r_vector(window)
    r_matrix = get_r_matrix(r_vector)
    a_vector = get_a_vector(r_matrix)
    return a_vector

def lpc_coeffs_list(signal, window_semi_size):
    s_length = len(signal)
    window_size = window_semi_size * 2
    start = 0
    lpc_list = []
    while True:
        window = signal[start : start + window_size]
        lpc_list.append(lpc_coeffs(window))
        start += window_semi_size
        if start + window_size > s_length:
            break
    return lpc_list

###########################################################
#                                                         #
#  Calcul de la matrice des distances entre deux signaux  #
#                                                         #
###########################################################

def euclidean_distance(vect1, vect2):
    return np.sqrt(sum((vect1 - vect2) ** 2))

def matrice_distances(coeffs_1, coeffs_2):
    distance_matrix = np.zeros((len(coeffs_1), len(coeffs_2)))
    # on calcule la première distance (0,0)
    distance_matrix[0,0] = euclidean_distance(coeffs_1[0], coeffs_2[0])
    # on calcule le long de la première colonne
    for i in range(1, len(distance_matrix)):
        distance_matrix[i,0] = distance_matrix[i-1,0] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[0])
    # on calcule le long de la première ligne
    for j in range(1, len(distance_matrix[0])):
        distance_matrix[0,j] = distance_matrix[0,j-1] + omega_h * euclidean_distance(coeffs_1[0], coeffs_2[j])
    # on calcule pour le reste du tableau
    for j in range(1, len(distance_matrix[0])):
        for i in range(1, len(distance_matrix)):
            dist_h = distance_matrix[i,j-1] + omega_h * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_v = distance_matrix[i-1,j] + omega_v * euclidean_distance(coeffs_1[i], coeffs_2[j])
            dist_d = distance_matrix[i-1,j-1] + omega_d * euclidean_distance(coeffs_1[i], coeffs_2[j])
            distance_matrix[i,j] = min(dist_h, dist_v, dist_d)
    # on retourne la matrice des distances
    return distance_matrix

def distance_entre_signaux(s1, s2, window_semi_size):
    coeffs_1 = lpc_coeffs_list(s1, window_semi_size)
    coeffs_2 = lpc_coeffs_list(s2, window_semi_size)
    matrice = matrice_distances(coeffs_1, coeffs_2)
    return matrice[-1,-1] / (len(coeffs_1) + len(coeffs_2))

##########################################################
#                                                        #
#  Calcul et enregistrement de la matrice des distances  #
#                                                        #
##########################################################

sample_size = 150

def chargement_donnees():
    file_names = os.listdir(path)
    shuffle(file_names)
    file_names = file_names[:sample_size]
    X = [ path + name for name in file_names ]
    Y = [ int(name[0]) for name in file_names ]
    delimitation = int(0.8*len(X))
    Xapp = X[:delimitation]
    Yapp = Y[:delimitation]
    Xtest = X[delimitation:]
    Ytest = Y[delimitation:]
    return Xapp, np.array(Yapp), Xtest, np.array(Ytest)

Xapp, Yapp, Xtest, Ytest = chargement_donnees()
with open("xapp.txt", "wb") as fp:
    pickle.dump(Xapp, fp)
with open("xtest.txt", "wb") as fp:
    pickle.dump(Xtest, fp)
np.save("yapp", Yapp)
np.save("ytest", Ytest)

def kppv_distances(Xtest, Xapp):
    Dist = np.zeros((len(Xtest), len(Xapp)))
    for i in range(len(Xtest)):
        Fe, s1 = wav.read(Xtest[i])
        if (len(s1.shape) > 1) : s1 = s1[:,0]
        window_semi_size = int(Fe * duree_trame / 2)
        for j in range(len(Xapp)):
            _, s2 = wav.read(Xapp[j])
            if (len(s2.shape) > 1) : s2 = s2[:,0]
            Dist[i,j] = distance_entre_signaux(s1, s2, window_semi_size)
    return Dist

Dist = kppv_distances(Xtest, Xapp)
np.save("dist", Dist)

def kppv_predict(Dist, Yapp, K):
    N = Dist.shape[0]
    Ypred = np.zeros(N, dtype=int)
    for i in range(N):
        kppv = Yapp[Dist[i,:].argsort()[:K]]
        Ypred[i] = np.argmax(np.bincount(kppv))
    return Ypred

def evaluation_classifieur(Ytest, Ypred):
    return (Ytest == Ypred).sum() / Ytest.shape[0]

def performance(K):
    Ypred = kppv_predict(Dist, Yapp, K)
    return evaluation_classifieur(Ytest, Ypred)

les_k = [ k for k in range(1,20) ]
les_accuracy = [ performance(k) for k in les_k ]

plt.xlabel('K')
plt.ylabel('Accuracy')
plt.title('Accuracy(K) avec (ordre = ' + str(ordre) + ', oh = ' + str(omega_h) + ', od = ' + str(omega_d) + ', oh = ' + str(omega_h) + ')')
plt.plot(les_k, les_accuracy, 'ro')
plt.save("accuracies_ordre_" + str(ordre) + "_omega_" + str(omega_v))

index_max = np.asarray(les_accuracy).argsort()[-1]
print('La meilleure Accuracy ' + str(les_accuracy[index_max]) + ' est atteinte pour K = ' + str(les_k[index_max]))

finish = time.time()
minutes = int(finish - start) / 60
print('Duree execution pour sample_size = '  + str(sample_size) +  ' : ' + str(minutes) + ' minutes !')
print("\007")

"""Duree execution pour sample_size = 50 : 1,166666666666667 minutes !
Duree execution pour sample_size = 100 : 7.783333333333333 minutes !
Duree execution pour sample_size = 150 : 13.016666666666667 minutes !
Duree execution pour sample_size = 200 : 24.75 minutes !"""
